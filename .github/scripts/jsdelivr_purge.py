#!/usr/bin/env python3
"""Purge mutable jsDelivr aliases for changed public files."""

from __future__ import annotations

import argparse
import concurrent.futures
import dataclasses
import hashlib
import html
import json
import re
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path, PurePosixPath
from typing import Callable, Iterable, Mapping, Sequence


EMPTY_TREE_SHA = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"
PURGE_HOST = "purge.jsdelivr.net"
DEFAULT_PURGE_ATTEMPTS = 5
DEFAULT_PURGE_WORKERS = 2
RETRY_DELAYS = (2, 5, 10, 20, 30, 45, 60)
USER_AGENT = "Custom_OpenClash_Rules-jsDelivr-publisher/1.0"
WORKER_ROOT_FILES = ("README.md", "LICENCE")
WORKER_CANARY_PATH = "rule/Custom_Direct.list"
WORKER_MAX_ASSET_COUNT = 20_000
WORKER_MAX_ASSET_BYTES = 25 * 1024 * 1024


class PublishError(RuntimeError):
    """Raised when the publication contract or live verification fails."""


@dataclasses.dataclass(frozen=True)
class PublishContract:
    repository: str
    branch: str
    ref_aliases: tuple[str, ...]
    public_roots: frozenset[str]
    deferred_sources: frozenset[str]
    snapshot_deferred_inputs: frozenset[str]
    generated_suffixes: tuple[str, ...]
    excluded_prefixes: tuple[str, ...]
    excluded_path_parts: frozenset[str]
    excluded_basenames: frozenset[str]


@dataclasses.dataclass(frozen=True)
class AssetExpectation:
    path: str
    content: bytes | None

    @property
    def description(self) -> str:
        if self.content is None:
            return "deleted at published revision"
        digest = hashlib.sha256(self.content).hexdigest()
        return f"sha256={digest}, bytes={len(self.content)}"


@dataclasses.dataclass(frozen=True)
class HttpResult:
    status: int
    body: bytes


def _require_string_list(data: Mapping[str, object], key: str) -> tuple[str, ...]:
    value = data.get(key)
    if not isinstance(value, list) or not value or not all(
        isinstance(item, str) and item for item in value
    ):
        raise PublishError(f"Contract field {key!r} must be a non-empty string list")
    if len(value) != len(set(value)):
        raise PublishError(f"Contract field {key!r} contains duplicates")
    return tuple(value)


def load_contract(path: Path) -> PublishContract:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise PublishError(f"Unable to read publication contract {path}: {exc}") from exc

    if not isinstance(data, dict):
        raise PublishError("Publication contract must be a JSON object")

    repository = data.get("repository")
    branch = data.get("branch")
    if not isinstance(repository, str) or repository.count("/") != 1:
        raise PublishError("Contract repository must use owner/name format")
    if not isinstance(branch, str) or not branch:
        raise PublishError("Contract branch must be a non-empty string")

    aliases = _require_string_list(data, "ref_aliases")
    expected_aliases = (branch, f"refs/heads/{branch}")
    if aliases != expected_aliases:
        raise PublishError(
            f"ref_aliases must be exactly {expected_aliases!r} so both mutable cache keys are covered"
        )

    roots = _require_string_list(data, "public_roots")
    for root in roots:
        if PurePosixPath(root).parts != (root,) or root.startswith("."):
            raise PublishError(f"Invalid public root: {root!r}")

    deferred = _require_string_list(data, "deferred_sources")
    snapshot_deferred_inputs = _require_string_list(
        data, "snapshot_deferred_inputs"
    )
    prefixes = _require_string_list(data, "excluded_prefixes")
    excluded_parts = _require_string_list(data, "excluded_path_parts")
    excluded_names = _require_string_list(data, "excluded_basenames")

    generated_suffixes = _require_string_list(data, "generated_suffixes")
    if any(PurePosixPath(suffix).parts != (suffix,) for suffix in generated_suffixes):
        raise PublishError("generated_suffixes entries must be file-name suffixes")

    contract = PublishContract(
        repository=repository,
        branch=branch,
        ref_aliases=aliases,
        public_roots=frozenset(roots),
        deferred_sources=frozenset(deferred),
        snapshot_deferred_inputs=frozenset(snapshot_deferred_inputs),
        generated_suffixes=generated_suffixes,
        excluded_prefixes=prefixes,
        excluded_path_parts=frozenset(part.casefold() for part in excluded_parts),
        excluded_basenames=frozenset(name.casefold() for name in excluded_names),
    )
    for source in contract.deferred_sources:
        if not is_public_path(source, contract):
            raise PublishError(f"Deferred source is not a public path: {source}")
    for path in contract.snapshot_deferred_inputs:
        normalize_repo_path(path)
    for path in deferred_publication_paths(contract):
        if not is_public_path(path, contract):
            raise PublishError(f"Deferred generated path is not public: {path}")
    return contract


def normalize_repo_path(path: str) -> str:
    if not path or "\\" in path or path.startswith("/"):
        raise PublishError(f"Unsafe repository path: {path!r}")
    parts = PurePosixPath(path).parts
    if not parts or any(part in ("", ".", "..") for part in parts):
        raise PublishError(f"Unsafe repository path: {path!r}")
    normalized = "/".join(parts)
    if normalized != path:
        raise PublishError(f"Repository path is not normalized: {path!r}")
    return normalized


def is_public_path(path: str, contract: PublishContract) -> bool:
    try:
        normalized = normalize_repo_path(path)
    except PublishError:
        return False
    parts = PurePosixPath(normalized).parts
    if parts[0] not in contract.public_roots:
        return False
    if any(part.casefold() in contract.excluded_path_parts for part in parts):
        return False
    if parts[-1].casefold() in contract.excluded_basenames:
        return False
    return not any(
        normalized == prefix or normalized.startswith(f"{prefix}/")
        for prefix in contract.excluded_prefixes
    )


def should_publish_path(path: str, contract: PublishContract, mode: str) -> bool:
    if not is_public_path(path, contract):
        return False
    if mode == "direct" and path in deferred_publication_paths(contract):
        return False
    if mode not in ("direct", "complete"):
        raise PublishError(f"Unknown publication mode: {mode}")
    return True


def deferred_publication_paths(contract: PublishContract) -> frozenset[str]:
    paths = set(contract.deferred_sources)
    for source in contract.deferred_sources:
        source_path = PurePosixPath(source)
        for suffix in contract.generated_suffixes:
            paths.add(f"{source_path.parent.as_posix()}/{source_path.stem}_{suffix}")
    return frozenset(paths)


def run_git(args: Sequence[str], *, text: bool = False) -> bytes | str:
    completed = subprocess.run(
        ["git", *args],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=text,
        encoding="utf-8" if text else None,
    )
    if completed.returncode != 0:
        stderr = completed.stderr.strip() if text else completed.stderr.decode("utf-8", "replace").strip()
        raise PublishError(f"git {' '.join(args)} failed: {stderr}")
    return completed.stdout


def resolve_commit(revision: str) -> str:
    output = run_git(["rev-parse", "--verify", f"{revision}^{{commit}}"], text=True)
    assert isinstance(output, str)
    return output.strip()


def resolve_range(before: str, after: str) -> tuple[str, str]:
    after_sha = resolve_commit(after)
    if not before or set(before) == {"0"}:
        before_sha = EMPTY_TREE_SHA
    else:
        before_sha = resolve_commit(before)
        completed = subprocess.run(
            ["git", "merge-base", "--is-ancestor", before_sha, after_sha],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
        )
        if completed.returncode != 0:
            raise PublishError(f"Before revision {before_sha} is not an ancestor of {after_sha}")
    return before_sha, after_sha


def parse_name_status_z(raw: bytes) -> list[tuple[str, tuple[str, ...]]]:
    fields = raw.split(b"\0")
    if fields and fields[-1] == b"":
        fields.pop()
    changes: list[tuple[str, tuple[str, ...]]] = []
    index = 0
    while index < len(fields):
        status = fields[index].decode("ascii", "strict")
        index += 1
        path_count = 2 if status.startswith(("R", "C")) else 1
        if index + path_count > len(fields):
            raise PublishError("Malformed NUL-delimited git diff output")
        paths = tuple(field.decode("utf-8", "surrogateescape") for field in fields[index : index + path_count])
        changes.append((status, paths))
        index += path_count
    return changes


def blob_at(revision: str, path: str) -> bytes:
    output = run_git(["cat-file", "blob", f"{revision}:{path}"])
    assert isinstance(output, bytes)
    return output


def blob_or_none(revision: str, path: str) -> bytes | None:
    completed = subprocess.run(
        ["git", "cat-file", "-t", f"{revision}:{path}"],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
    )
    if completed.returncode != 0:
        return None
    if completed.stdout.strip() != "blob":
        raise PublishError(f"Published path is not a regular file: {path}")
    return blob_at(revision, path)


def build_expectations(
    before_sha: str,
    after_sha: str,
    contract: PublishContract,
    mode: str,
    published_sha: str | None = None,
) -> list[AssetExpectation]:
    content_sha = published_sha or after_sha
    raw = run_git(
        ["diff", "--name-status", "-z", "--find-renames", before_sha, after_sha, "--"]
    )
    assert isinstance(raw, bytes)
    changed_paths: set[str] = set()
    for status, paths in parse_name_status_z(raw):
        kind = status[0]
        if kind == "R":
            old_path, new_path = paths
            if should_publish_path(old_path, contract, mode):
                changed_paths.add(old_path)
            if should_publish_path(new_path, contract, mode):
                changed_paths.add(new_path)
            continue
        if kind == "C":
            _old_path, new_path = paths
            if should_publish_path(new_path, contract, mode):
                changed_paths.add(new_path)
            continue

        (path,) = paths
        if not should_publish_path(path, contract, mode):
            continue
        if kind not in ("A", "D", "M", "T"):
            raise PublishError(f"Unsupported git change status {status!r} for {path}")
        changed_paths.add(path)

    return [
        AssetExpectation(path=path, content=blob_or_none(content_sha, path))
        for path in sorted(changed_paths)
    ]


def changed_paths_between(before_sha: str, after_sha: str) -> frozenset[str]:
    raw = run_git(
        ["diff", "--name-status", "-z", "--find-renames", before_sha, after_sha, "--"]
    )
    assert isinstance(raw, bytes)
    paths: set[str] = set()
    for _status, changed_paths in parse_name_status_z(raw):
        for path in changed_paths:
            paths.add(normalize_repo_path(path))
    return frozenset(paths)


def worker_snapshot_generation_inputs(
    contract: PublishContract,
) -> frozenset[str]:
    return contract.deferred_sources | contract.snapshot_deferred_inputs


def plan_worker_snapshot(
    before_sha: str,
    after_sha: str,
    contract: PublishContract,
    *,
    generation_complete: bool,
) -> tuple[bool, tuple[str, ...]]:
    changed = changed_paths_between(before_sha, after_sha)
    blocked = tuple(sorted(changed & worker_snapshot_generation_inputs(contract)))
    if blocked and not generation_complete:
        return False, blocked
    return True, blocked


def worker_asset_prefix(contract: PublishContract) -> str:
    repository_name = contract.repository.split("/", 1)[1]
    return f"{repository_name}/{contract.branch}"


def list_worker_snapshot_blobs(
    revision_sha: str, contract: PublishContract
) -> list[tuple[str, bytes]]:
    raw = run_git(["ls-tree", "-r", "-z", "--full-tree", revision_sha])
    assert isinstance(raw, bytes)
    selected: list[tuple[str, bytes]] = []
    root_files = frozenset(WORKER_ROOT_FILES)
    for entry in raw.split(b"\0"):
        if not entry:
            continue
        try:
            metadata, encoded_path = entry.split(b"\t", 1)
            mode, object_type, _object_sha = metadata.decode("ascii").split(" ")
            path = encoded_path.decode("utf-8", "surrogateescape")
        except (ValueError, UnicodeDecodeError) as exc:
            raise PublishError("Malformed git ls-tree output") from exc

        selected_path = path in root_files or is_public_path(path, contract)
        if not selected_path:
            continue
        normalize_repo_path(path)
        if object_type != "blob" or mode not in ("100644", "100755"):
            raise PublishError(
                f"Worker snapshot path is not a regular file: {path} "
                f"(mode={mode}, type={object_type})"
            )
        content = blob_at(revision_sha, path)
        if len(content) > WORKER_MAX_ASSET_BYTES:
            raise PublishError(
                f"Worker snapshot file exceeds 25 MiB: {path} ({len(content)} bytes)"
            )
        selected.append((path, content))

    selected.sort(key=lambda item: item[0])
    if not selected:
        raise PublishError("Worker snapshot contains no public files")
    if len(selected) + 2 > WORKER_MAX_ASSET_COUNT:
        raise PublishError(
            f"Worker snapshot exceeds the free-plan file limit: {len(selected) + 2}"
        )
    return selected


def commit_timestamp(revision_sha: str) -> str:
    output = run_git(["show", "-s", "--format=%cI", revision_sha], text=True)
    assert isinstance(output, str)
    value = output.strip()
    if not value:
        raise PublishError(f"Commit {revision_sha} has no timestamp")
    return value


def write_worker_snapshot(
    revision: str, output: Path, contract: PublishContract
) -> dict[str, object]:
    revision_sha = resolve_commit(revision)
    output = output.resolve()
    if output.exists():
        if not output.is_dir():
            raise PublishError(f"Worker asset output path is not a directory: {output}")
        if any(output.iterdir()):
            raise PublishError(f"Worker asset output directory is not empty: {output}")
    output.mkdir(parents=True, exist_ok=True)

    prefix = worker_asset_prefix(contract)
    blobs = list_worker_snapshot_blobs(revision_sha, contract)
    file_entries: dict[str, dict[str, object]] = {}
    total_bytes = 0
    for path, content in blobs:
        destination = output.joinpath(*PurePosixPath(prefix, path).parts)
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(content)
        file_entries[path] = {
            "bytes": len(content),
            "sha256": hashlib.sha256(content).hexdigest(),
        }
        total_bytes += len(content)

    canary = file_entries.get(WORKER_CANARY_PATH)
    if canary is None:
        raise PublishError(f"Worker canary is missing: {WORKER_CANARY_PATH}")

    published_at = commit_timestamp(revision_sha)
    index = f"""<!doctype html>
<html lang=\"zh-CN\">
<head>
  <meta charset=\"utf-8\">
  <meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">
  <title>Custom_OpenClash_Rules main 镜像</title>
</head>
<body>
  <h1>Custom_OpenClash_Rules</h1>
  <p>这里提供 <code>main</code> 分支最后一次完整验证并部署的只读文件快照。</p>
  <p>快照提交：<code>{html.escape(revision_sha)}</code></p>
  <p>提交时间：<time>{html.escape(published_at)}</time></p>
  <ul>
    <li><a href=\"./README.md\">README.md</a></li>
    <li><a href=\"./rule/Custom_Direct.list\">Custom_Direct.list</a></li>
    <li><a href=\"/_mirror/Custom_OpenClash_Rules/main.json\">快照清单</a></li>
  </ul>
</body>
</html>
"""
    index_path = output.joinpath(*PurePosixPath(prefix, "index.html").parts)
    index_path.write_text(index, encoding="utf-8", newline="\n")

    manifest: dict[str, object] = {
        "repository": contract.repository,
        "branch": contract.branch,
        "commit": revision_sha,
        "published_at": published_at,
        "file_count": len(file_entries),
        "total_bytes": total_bytes,
        "canary": {
            "path": WORKER_CANARY_PATH,
            "bytes": canary["bytes"],
            "sha256": canary["sha256"],
        },
        "files": file_entries,
    }
    manifest_path = output / "_mirror" / contract.repository.split("/", 1)[1]
    manifest_path.mkdir(parents=True, exist_ok=True)
    (manifest_path / f"{contract.branch}.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )

    headers = f"""/{prefix}/*
  Access-Control-Allow-Origin: *
  Cache-Control: public, max-age=300
  X-Content-Type-Options: nosniff
  X-Robots-Tag: noindex, nofollow, nosnippet

/{prefix}/
  Content-Security-Policy: default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; frame-ancestors 'none'

/_mirror/*
  Access-Control-Allow-Origin: *
  Cache-Control: no-store, max-age=0
  X-Content-Type-Options: nosniff
  X-Robots-Tag: noindex, nofollow, nosnippet
"""
    (output / "_headers").write_text(headers, encoding="utf-8", newline="\n")

    print(
        f"Built Worker snapshot {revision_sha}: "
        f"{len(file_entries)} files, {total_bytes} bytes"
    )
    return manifest


def encoded_asset_path(path: str) -> str:
    return urllib.parse.quote(normalize_repo_path(path), safe="/")


def alias_path(repository: str, alias: str, path: str) -> str:
    return f"/gh/{repository}@{alias}/{encoded_asset_path(path)}"


def request_url(url: str, timeout: float = 30.0) -> HttpResult:
    request = urllib.request.Request(
        url,
        headers={"Accept": "application/json, */*", "User-Agent": USER_AGENT},
        method="GET",
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return HttpResult(status=response.status, body=response.read())
    except urllib.error.HTTPError as exc:
        return HttpResult(status=exc.code, body=exc.read())


def validate_purge_response(result: HttpResult, expected_path: str) -> None:
    if result.status != 200:
        raise PublishError(f"Purge returned HTTP {result.status} for {expected_path}")
    try:
        payload = json.loads(result.body.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise PublishError(f"Purge returned invalid JSON for {expected_path}: {exc}") from exc
    if not isinstance(payload, dict) or payload.get("status") != "finished":
        raise PublishError(f"Purge did not finish for {expected_path}: {payload!r}")


def purge_target(
    repository: str,
    alias: str,
    path: str,
    *,
    requester: Callable[[str], HttpResult] = request_url,
    attempts: int = DEFAULT_PURGE_ATTEMPTS,
    sleeper: Callable[[float], None] = time.sleep,
) -> str:
    expected_path = alias_path(repository, alias, path)
    url = f"https://{PURGE_HOST}{expected_path}"
    errors: list[str] = []
    for attempt in range(attempts):
        try:
            validate_purge_response(requester(url), expected_path)
            return url
        except (OSError, PublishError) as exc:
            errors.append(str(exc))
            if attempt + 1 < attempts:
                sleeper(RETRY_DELAYS[min(attempt, len(RETRY_DELAYS) - 1)])
    raise PublishError(f"Purge failed after {attempts} attempts for {url}: {errors[-1]}")


def purge_all(
    expectations: Sequence[AssetExpectation],
    contract: PublishContract,
    *,
    workers: int = DEFAULT_PURGE_WORKERS,
) -> None:
    targets = [
        (alias, expectation.path)
        for expectation in expectations
        for alias in contract.ref_aliases
    ]
    errors: list[str] = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as executor:
        futures = {
            executor.submit(purge_target, contract.repository, alias, path): (alias, path)
            for alias, path in targets
        }
        for future in concurrent.futures.as_completed(futures):
            alias, path = futures[future]
            try:
                url = future.result()
                print(f"Purged {url}", flush=True)
            except Exception as exc:  # noqa: BLE001 - aggregate all provider failures
                errors.append(f"{alias}/{path}: {exc}")
    if errors:
        raise PublishError("One or more purge requests failed:\n" + "\n".join(errors))


def _own_jsdelivr_urls(repository: str, revision: str) -> Iterable[str]:
    pattern = rf"https://(cdn|testingcf)\.jsdelivr\.net/gh/{re.escape(repository)}@"
    completed = subprocess.run(
        ["git", "grep", "-I", "-h", "-E", pattern, revision, "--"],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
    )
    if completed.returncode not in (0, 1):
        raise PublishError(f"git grep failed: {completed.stderr.strip()}")
    url_pattern = re.compile(
        rf"https://(?:cdn|testingcf)\.jsdelivr\.net/gh/{re.escape(repository)}@[^\s\"'<>\)\]]+"
    )
    for match in url_pattern.finditer(completed.stdout):
        yield match.group(0).rstrip(".,;，。；")


def validate_contract_urls(contract: PublishContract, revision: str) -> int:
    revision_sha = resolve_commit(revision)
    errors: list[str] = []
    count = 0
    base = f"/gh/{contract.repository}@"
    aliases = sorted(contract.ref_aliases, key=len, reverse=True)
    for url in _own_jsdelivr_urls(contract.repository, revision_sha):
        count += 1
        parsed = urllib.parse.urlsplit(url)
        if not parsed.path.startswith(base):
            errors.append(f"Malformed own-repository jsDelivr URL: {url}")
            continue
        remainder = parsed.path[len(base) :]
        alias = next(
            (candidate for candidate in aliases if remainder.startswith(f"{candidate}/")),
            None,
        )
        if alias is None:
            errors.append(f"URL does not use a declared mutable alias: {url}")
            continue
        path = urllib.parse.unquote(remainder[len(alias) + 1 :])
        if not is_public_path(path, contract):
            errors.append(f"URL target is outside the public contract: {url}")
    if errors:
        raise PublishError("Publication contract URL check failed:\n" + "\n".join(sorted(set(errors))))
    print(f"Validated {count} own-repository jsDelivr URLs at {revision_sha}")
    return count


def print_plan(
    expectations: Sequence[AssetExpectation],
    before_sha: str,
    after_sha: str,
    published_sha: str,
    mode: str,
) -> None:
    print(f"Changed-path range: {before_sha}..{after_sha}")
    print(f"Published main snapshot: {published_sha}")
    print(f"Publication mode: {mode}")
    if not expectations:
        print("No changed public assets require cache publication.")
        return
    print(f"Changed public assets: {len(expectations)}")
    for expectation in expectations:
        action = "delete" if expectation.content is None else "publish"
        print(f"  {action}: {expectation.path} ({expectation.description})")


def command_run(args: argparse.Namespace) -> None:
    contract = load_contract(args.contract)
    if args.repository != contract.repository:
        raise PublishError(
            f"Refusing to purge {args.repository}; contract is bound to {contract.repository}"
        )
    before_sha, after_sha = resolve_range(args.before, args.after)
    published_sha = resolve_commit(args.published)
    completed = subprocess.run(
        ["git", "merge-base", "--is-ancestor", after_sha, published_sha],
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.PIPE,
    )
    if completed.returncode != 0:
        raise PublishError(
            f"Requested revision {after_sha} is not an ancestor of published main {published_sha}"
        )
    expectations = build_expectations(
        before_sha, after_sha, contract, args.mode, published_sha
    )
    print_plan(expectations, before_sha, after_sha, published_sha, args.mode)
    if not expectations:
        return
    purge_all(expectations, contract)


def command_plan_worker_snapshot(args: argparse.Namespace) -> None:
    contract = load_contract(args.contract)
    before_sha, after_sha = resolve_range(args.before, args.after)
    deployable, blocked = plan_worker_snapshot(
        before_sha,
        after_sha,
        contract,
        generation_complete=args.generation_complete,
    )
    reason = "ready"
    if blocked and not args.generation_complete:
        reason = "waiting_for_generated_outputs"
    elif blocked:
        reason = "generation_complete"
    print(f"Worker snapshot plan: deployable={str(deployable).lower()}, reason={reason}")
    if blocked:
        print("Generation-sensitive paths in range:")
        for path in blocked:
            print(f"  {path}")
    if args.github_output is not None:
        with args.github_output.open("a", encoding="utf-8", newline="\n") as handle:
            handle.write(f"worker_deployable={str(deployable).lower()}\n")
            handle.write(f"worker_plan_reason={reason}\n")
            handle.write(f"worker_after_sha={after_sha}\n")


def command_build_worker_assets(args: argparse.Namespace) -> None:
    contract = load_contract(args.contract)
    write_worker_snapshot(args.revision, args.output, contract)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--contract",
        type=Path,
        default=Path(".github/jsdelivr-publish.json"),
        help="Path to the publication contract",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    check = subparsers.add_parser("check-contract", help="Validate owned jsDelivr URLs")
    check.add_argument("--revision", default="HEAD")

    run = subparsers.add_parser("run", help="Purge changed public files")
    run.add_argument("--repository", required=True)
    run.add_argument("--before", required=True)
    run.add_argument("--after", required=True)
    run.add_argument(
        "--published",
        required=True,
        help="Latest main snapshot used to resolve current asset state",
    )
    run.add_argument("--mode", choices=("direct", "complete"), required=True)

    plan_worker = subparsers.add_parser(
        "plan-worker-snapshot",
        help="Decide whether an exact Worker snapshot is generation-complete",
    )
    plan_worker.add_argument("--before", required=True)
    plan_worker.add_argument("--after", required=True)
    plan_worker.add_argument("--generation-complete", action="store_true")
    plan_worker.add_argument("--github-output", type=Path)

    build_worker = subparsers.add_parser(
        "build-worker-assets",
        help="Build an exact Git revision as Workers Static Assets",
    )
    build_worker.add_argument("--revision", required=True)
    build_worker.add_argument("--output", type=Path, required=True)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        contract = load_contract(args.contract)
        if args.command == "check-contract":
            validate_contract_urls(contract, args.revision)
        elif args.command == "run":
            command_run(args)
        elif args.command == "plan-worker-snapshot":
            command_plan_worker_snapshot(args)
        elif args.command == "build-worker-assets":
            command_build_worker_assets(args)
        else:  # pragma: no cover - argparse enforces the command set
            parser.error(f"Unknown command: {args.command}")
    except PublishError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
