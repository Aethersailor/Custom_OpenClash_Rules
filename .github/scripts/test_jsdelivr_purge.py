from __future__ import annotations

import contextlib
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

import jsdelivr_purge as purge


REPOSITORY = "Aethersailor/Custom_OpenClash_Rules"


def contract() -> purge.PublishContract:
    return purge.PublishContract(
        repository=REPOSITORY,
        branch="main",
        ref_aliases=("main", "refs/heads/main"),
        verify_hosts=("cdn.jsdelivr.net", "testingcf.jsdelivr.net"),
        public_roots=frozenset(
            {"cfg", "game_rule", "icon", "overwrite", "rule", "script", "shell"}
        ),
        deferred_sources=frozenset(
            {
                "rule/Custom_Direct.list",
                "rule/Custom_Proxy.list",
                "rule/Steam_CDN.list",
                "rule/Encrypted_DNS.list",
                "rule/Game_Download_CDN.list",
            }
        ),
        generated_suffixes=(
            "Domain.yaml",
            "Domain.mrs",
            "IP.yaml",
            "IP.mrs",
            "Classical.yaml",
            "Classical_IP.yaml",
            "Classical_Port.yaml",
        ),
        excluded_prefixes=("overwrite/OpenClash_Overwrite",),
        excluded_path_parts=frozenset({"archived"}),
        excluded_basenames=frozenset({"readme.md"}),
    )


def git(*args: str, cwd: Path) -> str:
    return subprocess.run(
        ["git", *args],
        cwd=cwd,
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
    ).stdout.strip()


@contextlib.contextmanager
def working_directory(path: Path):
    previous = Path.cwd()
    os.chdir(path)
    try:
        yield
    finally:
        os.chdir(previous)


class ContractTests(unittest.TestCase):
    def test_public_surface_and_explicit_exclusions(self):
        value = contract()
        self.assertTrue(purge.is_public_path("cfg/example.ini", value))
        self.assertTrue(purge.is_public_path("rule/static.yaml", value))
        self.assertTrue(purge.is_public_path("icon/match.png", value))
        self.assertFalse(purge.is_public_path("py/generate_rules.py", value))
        self.assertFalse(purge.is_public_path("rule/archived/old.yaml", value))
        self.assertFalse(purge.is_public_path("game_rule/README.md", value))
        self.assertFalse(
            purge.is_public_path("overwrite/OpenClash_Overwrite", value)
        )
        self.assertFalse(
            purge.is_public_path("overwrite/OpenClash_Overwrite/file.yaml", value)
        )

    def test_direct_mode_defers_only_generated_sources(self):
        value = contract()
        self.assertFalse(
            purge.should_publish_path("rule/Custom_Proxy.list", value, "direct")
        )
        self.assertFalse(
            purge.should_publish_path("rule/Custom_Proxy_IP.mrs", value, "direct")
        )
        self.assertTrue(
            purge.should_publish_path("rule/Custom_Proxy.list", value, "complete")
        )
        self.assertTrue(
            purge.should_publish_path("rule/Custom_Proxy_IP.mrs", value, "complete")
        )
        self.assertTrue(
            purge.should_publish_path("rule/IPTVMainland_Domain.list", value, "direct")
        )

    def test_alias_paths_encode_unicode_without_losing_slashes(self):
        path = purge.alias_path(REPOSITORY, "refs/heads/main", "规则/测试 文件.yaml")
        self.assertEqual(
            path,
            "/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/"
            "%E8%A7%84%E5%88%99/%E6%B5%8B%E8%AF%95%20%E6%96%87%E4%BB%B6.yaml",
        )

    def test_name_status_parser_handles_rename_and_unicode(self):
        raw = "R100\0旧.yaml\0新.yaml\0M\0cfg/a.ini\0".encode()
        self.assertEqual(
            purge.parse_name_status_z(raw),
            [("R100", ("旧.yaml", "新.yaml")), ("M", ("cfg/a.ini",))],
        )

    def test_repository_contract_matches_rule_generator(self):
        root = Path(__file__).resolve().parents[2]
        value = purge.load_contract(root / ".github/jsdelivr-publish.json")
        module_path = root / "py/generate_rules.py"
        spec = importlib.util.spec_from_file_location("rule_generator_contract", module_path)
        self.assertIsNotNone(spec)
        self.assertIsNotNone(spec.loader)
        module = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = module
        try:
            spec.loader.exec_module(module)
        finally:
            sys.modules.pop(spec.name, None)

        expected_sources = {
            f"rule/{base_name}.list" for base_name in module.BASE_NAMES
        }
        self.assertEqual(value.deferred_sources, expected_sources)

        outputs, mrs_inputs = module.textual_outputs(root)
        generated_suffixes = set()
        for path in (*outputs, *mrs_inputs):
            for base_name in module.BASE_NAMES:
                prefix = f"{base_name}_"
                if path.name.startswith(prefix):
                    generated_suffixes.add(path.name[len(prefix) :])
                    break
        self.assertEqual(set(value.generated_suffixes), generated_suffixes)


class GitPlanningTests(unittest.TestCase):
    def test_add_delete_rename_and_deferred_source(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            repo = Path(temp_dir)
            git("init", "-b", "main", cwd=repo)
            git("config", "user.name", "Test", cwd=repo)
            git("config", "user.email", "test@example.com", cwd=repo)
            for directory in ("cfg", "rule", "icon"):
                (repo / directory).mkdir()
            (repo / "cfg/old.ini").write_bytes(b"old\n")
            (repo / "rule/static.yaml").write_bytes(b"old static\n")
            (repo / "rule/Custom_Proxy.list").write_bytes(b"old source\n")
            git("add", ".", cwd=repo)
            git("commit", "-m", "initial", cwd=repo)
            before = git("rev-parse", "HEAD", cwd=repo)

            git("mv", "cfg/old.ini", "cfg/new.ini", cwd=repo)
            (repo / "cfg/new.ini").write_bytes(b"new\n")
            (repo / "rule/static.yaml").unlink()
            (repo / "rule/Custom_Proxy.list").write_bytes(b"new source\n")
            (repo / "icon/测试.png").write_bytes(b"png")
            git("add", "-A", cwd=repo)
            git("commit", "-m", "change", cwd=repo)
            after = git("rev-parse", "HEAD", cwd=repo)

            with working_directory(repo):
                complete = {
                    item.path: item.content
                    for item in purge.build_expectations(
                        before, after, contract(), "complete"
                    )
                }
                direct = {
                    item.path: item.content
                    for item in purge.build_expectations(
                        before, after, contract(), "direct"
                    )
                }

            self.assertEqual(
                complete,
                {
                    "cfg/new.ini": b"new\n",
                    "cfg/old.ini": None,
                    "icon/测试.png": b"png",
                    "rule/Custom_Proxy.list": b"new source\n",
                    "rule/static.yaml": None,
                },
            )
            expected_direct = dict(complete)
            del expected_direct["rule/Custom_Proxy.list"]
            self.assertEqual(direct, expected_direct)

            # A queued purge may start after main has advanced. Its changed-path
            # set stays fixed, while expectations must follow the current branch.
            (repo / "cfg/new.ini").write_bytes(b"newest\n")
            (repo / "cfg/old.ini").write_bytes(b"reintroduced\n")
            git("add", "cfg", cwd=repo)
            git("commit", "-m", "advance main", cwd=repo)
            published = git("rev-parse", "HEAD", cwd=repo)
            with working_directory(repo):
                advanced = {
                    item.path: item.content
                    for item in purge.build_expectations(
                        before, after, contract(), "complete", published
                    )
                }
            self.assertEqual(advanced["cfg/new.ini"], b"newest\n")
            self.assertEqual(advanced["cfg/old.ini"], b"reintroduced\n")
            self.assertNotIn("cfg/unrelated.ini", advanced)

    def test_range_must_be_ancestral(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            repo = Path(temp_dir)
            git("init", "-b", "main", cwd=repo)
            git("config", "user.name", "Test", cwd=repo)
            git("config", "user.email", "test@example.com", cwd=repo)
            (repo / "file").write_text("one", encoding="utf-8")
            git("add", "file", cwd=repo)
            git("commit", "-m", "one", cwd=repo)
            first = git("rev-parse", "HEAD", cwd=repo)
            git("checkout", "--orphan", "other", cwd=repo)
            git("rm", "-f", "file", cwd=repo)
            (repo / "other").write_text("two", encoding="utf-8")
            git("add", "other", cwd=repo)
            git("commit", "-m", "two", cwd=repo)
            second = git("rev-parse", "HEAD", cwd=repo)
            with working_directory(repo):
                with self.assertRaisesRegex(purge.PublishError, "not an ancestor"):
                    purge.resolve_range(first, second)


class PurgeResponseTests(unittest.TestCase):
    def response(self, path: str, *, throttled=False, providers=None):
        if providers is None:
            providers = {"CF": True, "FY": True}
        body = {
            "status": "finished",
            "paths": {
                path: {"throttled": throttled, "providers": providers},
            },
        }
        return purge.HttpResult(200, json.dumps(body).encode())

    def test_requires_exact_path_and_all_providers(self):
        path = "/gh/Aethersailor/Custom_OpenClash_Rules@main/cfg/a.ini"
        purge.validate_purge_response(self.response(path), path)
        with self.assertRaisesRegex(purge.PublishError, "omitted exact path"):
            purge.validate_purge_response(self.response(path + ".other"), path)
        with self.assertRaisesRegex(purge.PublishError, "providers failed"):
            purge.validate_purge_response(
                self.response(path, providers={"CF": True, "FY": False}), path
            )
        with self.assertRaisesRegex(purge.PublishError, "throttled"):
            purge.validate_purge_response(self.response(path, throttled=True), path)

    def test_retry_then_success(self):
        calls: list[str] = []
        sleeps: list[float] = []

        def requester(url: str) -> purge.HttpResult:
            calls.append(url)
            path = "/" + url.split("/", 3)[3]
            if len(calls) == 1:
                return purge.HttpResult(503, b"retry")
            return self.response(path)

        url = purge.purge_target(
            REPOSITORY,
            "main",
            "cfg/测试 文件.ini",
            requester=requester,
            attempts=2,
            sleeper=sleeps.append,
        )
        self.assertIn("%E6%B5%8B%E8%AF%95%20%E6%96%87%E4%BB%B6.ini", url)
        self.assertEqual(len(calls), 2)
        self.assertEqual(sleeps, [2])


class VerificationTests(unittest.TestCase):
    def test_content_and_deletion_expectations(self):
        content = purge.AssetExpectation("cfg/a.ini", b"expected")
        deleted = purge.AssetExpectation("cfg/deleted.ini", None)
        self.assertTrue(purge.result_matches(purge.HttpResult(200, b"expected"), content)[0])
        self.assertFalse(purge.result_matches(purge.HttpResult(200, b"stale"), content)[0])
        self.assertTrue(purge.result_matches(purge.HttpResult(404, b""), deleted)[0])
        self.assertFalse(purge.result_matches(purge.HttpResult(200, b"old"), deleted)[0])

    def test_verification_retries_only_stale_targets(self):
        target = purge.VerificationTarget(
            "https://cdn.jsdelivr.net/example", purge.AssetExpectation("cfg/a", b"new")
        )
        calls = 0
        sleeps: list[float] = []

        def requester(_url: str) -> purge.HttpResult:
            nonlocal calls
            calls += 1
            return purge.HttpResult(200, b"old" if calls == 1 else b"new")

        purge.verify_all(
            [target], requester=requester, attempts=2, workers=1, sleeper=sleeps.append
        )
        self.assertEqual(calls, 2)
        self.assertEqual(sleeps, [2])


class UrlContractTests(unittest.TestCase):
    def make_repository(self, url: str) -> tuple[tempfile.TemporaryDirectory, Path, str]:
        holder = tempfile.TemporaryDirectory()
        repo = Path(holder.name)
        git("init", "-b", "main", cwd=repo)
        git("config", "user.name", "Test", cwd=repo)
        git("config", "user.email", "test@example.com", cwd=repo)
        (repo / "links.txt").write_text(url, encoding="utf-8")
        git("add", "links.txt", cwd=repo)
        git("commit", "-m", "links", cwd=repo)
        return holder, repo, git("rev-parse", "HEAD", cwd=repo)

    def test_owned_url_must_use_public_root(self):
        holder, repo, revision = self.make_repository(
            f"https://cdn.jsdelivr.net/gh/{REPOSITORY}@main/private/file.txt"
        )
        self.addCleanup(holder.cleanup)
        with working_directory(repo):
            with self.assertRaisesRegex(purge.PublishError, "outside the public contract"):
                purge.validate_contract_urls(contract(), revision)

    def test_owned_url_accepts_both_declared_aliases(self):
        holder, repo, revision = self.make_repository(
            "\n".join(
                (
                    f"https://cdn.jsdelivr.net/gh/{REPOSITORY}@main/cfg/a.ini",
                    f"https://testingcf.jsdelivr.net/gh/{REPOSITORY}@refs/heads/main/rule/a.yaml",
                )
            )
        )
        self.addCleanup(holder.cleanup)
        with working_directory(repo):
            self.assertEqual(purge.validate_contract_urls(contract(), revision), 2)


if __name__ == "__main__":
    unittest.main()
