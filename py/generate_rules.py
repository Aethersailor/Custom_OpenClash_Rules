#!/usr/bin/env python3
"""Generate deterministic YAML and MRS rule providers from maintained LIST files."""

from __future__ import annotations

import argparse
import ipaddress
import os
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path


REPOSITORY = "Aethersailor/Custom_OpenClash_Rules"
BASE_NAMES = (
    "Custom_Direct",
    "Custom_Proxy",
    "Steam_CDN",
    "Encrypted_DNS",
    "Game_Download_CDN",
)
GAME_RULE_DIRECTORY = Path("rule/game_rule")
GENERATED_HEADER_PREFIX = "# Generated from "
GENERATED_YAML_SUFFIXES = (
    "Domain.yaml",
    "IP.yaml",
    "Classical.yaml",
    "Classical_IP.yaml",
    "Classical_Port.yaml",
)
GENERATED_MRS_SUFFIXES = ("Domain.mrs", "IP.mrs")


@dataclass(frozen=True)
class RuleFamily:
    domain: tuple[str, ...]
    ip: tuple[str, ...]
    classical: tuple[str, ...]
    classical_ip: tuple[str, ...]
    ports: tuple[str, ...]


def parse_list(path: Path) -> RuleFamily:
    domains: list[str] = []
    ips: list[str] = []
    classical_non_ip: list[str] = []
    classical_ips: list[str] = []
    ports: list[str] = []

    seen: set[str] = set()
    for line_number, raw_line in enumerate(path.read_text(encoding="utf-8-sig").splitlines(), 1):
        rule = raw_line.strip()
        if not rule or rule.startswith(("#", ";")):
            continue
        if rule in seen:
            raise ValueError(f"{path}:{line_number}: duplicate rule: {rule}")
        seen.add(rule)

        parts = [part.strip() for part in rule.split(",")]
        rule_type = parts[0]
        if len(parts) < 2:
            raise ValueError(f"{path}:{line_number}: malformed rule: {rule}")

        if rule_type == "DOMAIN":
            domains.append(parts[1])
            classical_non_ip.append(rule)
        elif rule_type == "DOMAIN-SUFFIX":
            domains.append(f"+.{parts[1]}")
            classical_non_ip.append(rule)
        elif rule_type == "DOMAIN-KEYWORD":
            domains.append(f"*{parts[1]}*")
            classical_non_ip.append(rule)
        elif rule_type == "DOMAIN-REGEX":
            classical_non_ip.append(rule)
        elif rule_type in {"IP-CIDR", "IP-CIDR6"}:
            try:
                network = ipaddress.ip_network(parts[1], strict=False)
            except ValueError as exc:
                raise ValueError(f"{path}:{line_number}: invalid CIDR: {parts[1]}") from exc
            expected_type = "IP-CIDR6" if network.version == 6 else "IP-CIDR"
            if rule_type != expected_type:
                raise ValueError(
                    f"{path}:{line_number}: {parts[1]} must use {expected_type}, not {rule_type}"
                )
            ips.append(str(network))
            classical_ips.append(f"{rule_type},{network},no-resolve")
        elif rule_type in {"SRC-PORT", "DST-PORT"}:
            ports.append(rule)
            classical_non_ip.append(rule)
        else:
            raise ValueError(f"{path}:{line_number}: unsupported rule type: {rule_type}")

    return RuleFamily(
        domain=tuple(sorted(domains)),
        ip=tuple(sorted(ips)),
        classical=tuple(sorted(classical_non_ip) + sorted(classical_ips)),
        classical_ip=tuple(sorted(ports) + sorted(classical_ips)),
        ports=tuple(sorted(ports)),
    )


def render_yaml(source: Path, payload: tuple[str, ...], quoted: bool) -> str:
    lines = [
        f"# Generated from {source.as_posix()}",
        f"# REPO: https://github.com/{REPOSITORY}",
        f"# SOURCE: https://github.com/{REPOSITORY}/blob/main/{source.as_posix()}",
        f"# TOTAL: {len(payload)}",
        "",
    ]
    if not payload:
        lines.append("payload: []")
    else:
        lines.append("payload:")
        for rule in payload:
            escaped = rule.replace("'", "''")
            needs_quotes = quoted or rule.startswith("DOMAIN-REGEX,")
            lines.append(f"  - '{escaped}'" if needs_quotes else f"  - {rule}")
    return "\n".join(lines) + "\n"


def source_paths(root: Path) -> tuple[Path, ...]:
    sources = [Path("rule") / f"{base_name}.list" for base_name in BASE_NAMES]
    game_rule_directory = root / GAME_RULE_DIRECTORY
    sources.extend(
        path.relative_to(root)
        for path in sorted(
            game_rule_directory.rglob("*.list"),
            key=lambda path: path.relative_to(game_rule_directory).as_posix().casefold(),
        )
    )
    return tuple(sources)


def textual_outputs(root: Path) -> tuple[dict[Path, str], dict[Path, tuple[str, str]]]:
    outputs: dict[Path, str] = {}
    mrs_inputs: dict[Path, tuple[str, str]] = {}

    for source in source_paths(root):
        base_name = source.stem
        family = parse_list(root / source)
        variants = {
            "Domain": (family.domain, True),
            "IP": (family.ip, True),
            "Classical": (family.classical, False),
            "Classical_IP": (family.classical_ip, False),
        }
        if source == Path("rule/Custom_Direct.list"):
            variants["Classical_Port"] = (family.ports, False)

        for suffix, (payload, quoted) in variants.items():
            relative = source.parent / f"{base_name}_{suffix}.yaml"
            outputs[relative] = render_yaml(source, payload, quoted)
            if suffix == "Domain":
                mrs_inputs[relative.with_suffix(".mrs")] = ("domain", relative.as_posix())
            elif suffix == "IP":
                mrs_inputs[relative.with_suffix(".mrs")] = ("ipcidr", relative.as_posix())

    return outputs, mrs_inputs


def write_text_outputs(root: Path, outputs: dict[Path, str]) -> None:
    for relative, content in outputs.items():
        destination = root / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(content, encoding="utf-8", newline="\n")


def managed_output_paths(root: Path) -> frozenset[Path]:
    """Return generated files that are safe for this script to remove."""
    managed: set[Path] = set()
    rule_root = root / "rule"
    if not rule_root.exists():
        return frozenset()

    for destination in rule_root.rglob("*.yaml"):
        try:
            with destination.open(encoding="utf-8-sig") as handle:
                first_line = handle.readline().strip()
        except OSError:
            continue
        if not first_line.startswith(GENERATED_HEADER_PREFIX):
            continue

        source = Path(first_line.removeprefix(GENERATED_HEADER_PREFIX))
        if (
            source.is_absolute()
            or ".." in source.parts
            or not source.parts
            or source.parts[0] != "rule"
            or source.suffix != ".list"
        ):
            continue

        relative = destination.relative_to(root)
        expected_names = {
            f"{source.stem}_{suffix}" for suffix in GENERATED_YAML_SUFFIXES
        }
        if relative.parent != source.parent or relative.name not in expected_names:
            continue

        managed.add(relative)
        for suffix in GENERATED_MRS_SUFFIXES:
            yaml_suffix = suffix.removesuffix(".mrs") + ".yaml"
            if relative.name == f"{source.stem}_{yaml_suffix}":
                mrs_relative = relative.with_suffix(".mrs")
                if (root / mrs_relative).exists():
                    managed.add(mrs_relative)

    # Game-rule MRS files are always generated. Include an unpaired leftover
    # so a manually removed YAML file cannot leave an undeletable binary.
    game_rule_root = root / GAME_RULE_DIRECTORY
    if game_rule_root.exists():
        for destination in game_rule_root.rglob("*.mrs"):
            if destination.name.endswith(
                tuple(f"_{suffix}" for suffix in GENERATED_MRS_SUFFIXES)
            ):
                managed.add(destination.relative_to(root))

    return frozenset(managed)


def orphan_output_paths(
    root: Path,
    outputs: dict[Path, str],
    mrs_inputs: dict[Path, tuple[str, str]],
) -> tuple[Path, ...]:
    expected = set(outputs) | set(mrs_inputs)
    return tuple(
        sorted(
            managed_output_paths(root) - expected,
            key=lambda path: path.as_posix().casefold(),
        )
    )


def remove_orphan_outputs(root: Path, orphans: tuple[Path, ...]) -> None:
    for relative in orphans:
        (root / relative).unlink(missing_ok=True)


def yaml_has_rules(content: str) -> bool:
    return any(line.startswith("  - ") for line in content.splitlines())


def build_mrs(
    root: Path,
    outputs: dict[Path, str],
    mrs_inputs: dict[Path, tuple[str, str]],
    mihomo: str,
) -> None:
    for mrs_relative, (behavior, yaml_name) in mrs_inputs.items():
        yaml_relative = Path(yaml_name)
        if not yaml_has_rules(outputs[yaml_relative]):
            # Mihomo cannot convert an empty provider. Keep the existing valid
            # placeholder MRS so templates retain their stable provider URL.
            continue

        destination = root / mrs_relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        temporary = destination.with_suffix(destination.suffix + ".tmp")
        try:
            subprocess.run(
                [mihomo, "convert-ruleset", behavior, "yaml", str(root / yaml_relative), str(temporary)],
                check=True,
            )
            os.replace(temporary, destination)
        finally:
            temporary.unlink(missing_ok=True)


def check_outputs(root: Path, outputs: dict[Path, str], mrs_inputs: dict[Path, tuple[str, str]], mihomo: str | None) -> int:
    failures: list[str] = []
    for relative in orphan_output_paths(root, outputs, mrs_inputs):
        failures.append(f"orphan generated file: {relative}")
    for relative, expected in outputs.items():
        destination = root / relative
        if not destination.exists():
            failures.append(f"missing generated file: {relative}")
        elif destination.read_text(encoding="utf-8-sig") != expected:
            failures.append(f"stale generated file: {relative}")

    if mihomo:
        with tempfile.TemporaryDirectory(prefix="cocr-mrs-check-") as temp_dir:
            temp_root = Path(temp_dir)
            write_text_outputs(temp_root, outputs)
            build_mrs(temp_root, outputs, mrs_inputs, mihomo)
            for mrs_relative, (_, yaml_name) in mrs_inputs.items():
                if not yaml_has_rules(outputs[Path(yaml_name)]):
                    # Empty providers are not convertible. If a stable
                    # placeholder MRS already exists (for example
                    # Custom_Proxy_IP), normal generation deliberately keeps
                    # it; providers without a published placeholder need none.
                    continue
                generated = temp_root / mrs_relative
                tracked = root / mrs_relative
                if not tracked.exists():
                    failures.append(f"missing generated file: {mrs_relative}")
                elif generated.read_bytes() != tracked.read_bytes():
                    failures.append(f"stale generated file: {mrs_relative}")

    if failures:
        for failure in failures:
            print(f"ERROR: {failure}")
        return 1
    print("All generated rule files are up to date.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--mihomo", help="Mihomo executable used to generate or verify MRS files")
    parser.add_argument("--check", action="store_true", help="verify without modifying files")
    args = parser.parse_args()

    root = args.root.resolve()
    outputs, mrs_inputs = textual_outputs(root)
    if args.check:
        return check_outputs(root, outputs, mrs_inputs, args.mihomo)

    orphans = orphan_output_paths(root, outputs, mrs_inputs)
    remove_orphan_outputs(root, orphans)
    write_text_outputs(root, outputs)
    if args.mihomo:
        build_mrs(root, outputs, mrs_inputs, args.mihomo)
    message = "Generated rule YAML files" + (
        " and non-empty MRS files." if args.mihomo else "."
    )
    if orphans:
        message += f" Removed {len(orphans)} orphan generated file(s)."
    print(message)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
