from __future__ import annotations

import shlex
import subprocess
import tempfile
import unittest
from pathlib import Path

import sync_installer_common


ROOT = sync_installer_common.ROOT
LIGHT = sync_installer_common.LIGHT_INSTALLER
FULL = sync_installer_common.FULL_INSTALLER
CPU_CHECK = ROOT / "shell" / "check_cpu_version.sh"


class InstallerContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.light = LIGHT.read_text(encoding="utf-8")
        cls.full = FULL.read_text(encoding="utf-8")

    def run_sh(self, script: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["sh", "-c", script],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )

    def source_command(self, path: Path) -> str:
        return (
            "PATH=/usr/bin:/bin:$PATH; export PATH; "
            "OPENCLASH_INSTALLER_LIB_ONLY=1; "
            "export OPENCLASH_INSTALLER_LIB_ONLY; "
            f". {shlex.quote(path.as_posix())}; "
        )

    def test_shared_implementations_do_not_drift(self) -> None:
        self.assertEqual(
            sync_installer_common.synchronized_light_content(
                self.light, self.full
            ),
            self.light,
        )

    def test_shell_syntax(self) -> None:
        for path in (LIGHT, FULL):
            with self.subTest(path=path.name):
                result = subprocess.run(
                    ["sh", "-n", str(path)],
                    cwd=ROOT,
                    text=True,
                    capture_output=True,
                    check=False,
                )
                self.assertEqual(result.returncode, 0, result.stderr)

    def test_both_public_scripts_load_without_running_main(self) -> None:
        for path in (LIGHT, FULL):
            with self.subTest(path=path.name):
                result = self.run_sh(self.source_command(path) + "exit 0")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, "")

    def test_required_base_contract(self) -> None:
        required = (
            "release_branch",
            "github_address_mod",
            "https://testingcf.jsdelivr.net/",
            "core_version",
            "enable",
            "refs/heads/package",
            "--force-reinstall",
            "opkg --noaction install",
            "apk add -s",
            "apk list -I luci-app-openclash",
            "--allow-downgrade",
            "get_installed_version",
            "openclash_core.sh",
        )
        for path, content in ((LIGHT, self.light), (FULL, self.full)):
            for token in required:
                with self.subTest(path=path.name, token=token):
                    self.assertIn(token, content)

    def test_removed_mechanisms_stay_removed(self) -> None:
        forbidden = (
            "openclash_update.sh",
            "one_key_update",
            "skip_safe_path_check",
            "raw.hellogithub.com",
            "curl --resolve",
            "core_asset_exists",
            "verify_core_version",
            "new_log_has_error",
            "validate_geo_databases",
            "validate_chnroute",
            "pidof clash",
            "90 秒",
        )
        for path, content in ((LIGHT, self.light), (FULL, self.full)):
            for token in forbidden:
                with self.subTest(path=path.name, token=token):
                    self.assertNotIn(token, content)

    def test_commit_locked_package_flow(self) -> None:
        for content in (self.light, self.full):
            self.assertIn('download_commit_file "$commit" version', content)
            self.assertIn(
                'download_openclash_package "$commit" "$file_name"', content
            )
            self.assertIn(
                '"${JSDELIVR_PACKAGE_PREFIX}${commit}/dev/${path}"', content
            )
            self.assertIn(
                '"${RAW_PACKAGE_PREFIX}/${commit}/dev/${file_name}"', content
            )
            self.assertIn('PACKAGE_MAX_ROUNDS="${PACKAGE_MAX_ROUNDS:-2}"', content)
            self.assertNotIn("OpenClash@package/dev/", content)

    def test_core_update_uses_builtin_url_resolution(self) -> None:
        expected_call = '"$core_script" "$core_type" ||'
        invalid_prefix_argument = (
            '"$core_script" "$core_type" "https://testingcf.jsdelivr.net/"'
        )
        for path, content in ((LIGHT, self.light), (FULL, self.full)):
            with self.subTest(path=path.name):
                self.assertIn(expected_call, content)
                self.assertNotIn(invalid_prefix_argument, content)

    def test_full_installer_resource_and_smart_contract(self) -> None:
        required = (
            "auto_smart_switch",
            "lgbm_auto_update",
            "smart_enable_lgbm",
            "https://v6.gh-proxy.org/",
            "Model-large.bin",
            "Model-middle.bin",
            "Model.bin",
            "openclash_geo.sh",
            "openclash_chnroute.sh",
            "openclash.sh",
            "/etc/config/openclash-set",
            'uci set openclash.config.lgbm_custom_url="$SELECTED_MODEL_URL"',
        )
        for token in required:
            with self.subTest(token=token):
                self.assertIn(token, self.full)
        self.assertNotIn(
            "set openclash.config.smart_enable_lgbm", self.full
        )
        self.assertIn(
            '"${GH_PROXY_PREFIX}${SELECTED_MODEL_URL}"', self.full
        )
        self.assertIn('target_tmp="${target}.new.$$"', self.full)
        self.assertIn('mv -f "$target_tmp" "$target"', self.full)

    def _render_feed(self, distro: str, content: str) -> str:
        with tempfile.TemporaryDirectory(
            prefix=".installer-contract-", dir=ROOT
        ) as temp_name:
            temp = Path(temp_name)
            feed = temp / "distfeeds.conf"
            feed.write_text(content, encoding="utf-8", newline="\n")
            command = (
                self.source_command(LIGHT)
                + "log_info() { :; }; log_ok() { :; }; "
                + f"TMP_DIR={shlex.quote(temp.as_posix())}; "
                + f"FEED_FILE={shlex.quote(feed.as_posix())}; "
                + f"DISTRO_ID={shlex.quote(distro)}; "
                + "prepare_temporary_feed || exit 20; "
                + 'cat "$FEED_FILE"; '
                + "restore_feed || exit 21; "
                + 'cmp -s "$FEED_FILE" "$FEED_BACKUP" || exit 22'
            )
            result = self.run_sh(command)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(feed.read_text(encoding="utf-8"), content)
            return result.stdout

    def test_immortalwrt_official_and_vsean_feeds_go_to_nju(self) -> None:
        third_party = "https://packages.example.test/custom/packages.adb"
        content = (
            "https://downloads.immortalwrt.org/snapshots/base/packages.adb\n"
            "https://mirrors.vsean.net/openwrt/snapshots/luci/packages.adb\n"
            f"{third_party}\n"
        )
        rendered = self._render_feed("immortalwrt", content)
        self.assertEqual(rendered.count("https://mirror.nju.edu.cn/immortalwrt"), 2)
        self.assertIn(third_party, rendered)
        self.assertNotIn("downloads.immortalwrt.org", rendered)
        self.assertNotIn("mirrors.vsean.net/openwrt", rendered)

    def test_openwrt_feed_goes_only_to_ustc_openwrt(self) -> None:
        third_party = "https://packages.example.test/custom"
        content = (
            "src/gz openwrt_core "
            "https://downloads.openwrt.org/releases/24.10/targets/x86/64\n"
            f"src/gz custom {third_party}\n"
        )
        rendered = self._render_feed("openwrt", content)
        self.assertIn("https://mirrors.ustc.edu.cn/openwrt/releases/", rendered)
        self.assertIn(third_party, rendered)
        self.assertNotIn("/immortalwrt", rendered)

    def test_unknown_feed_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory(
            prefix=".installer-contract-", dir=ROOT
        ) as temp_name:
            temp = Path(temp_name)
            feed = temp / "distfeeds.conf"
            original = "https://packages.example.test/custom\n"
            feed.write_text(original, encoding="utf-8", newline="\n")
            command = (
                self.source_command(LIGHT)
                + f"TMP_DIR={shlex.quote(temp.as_posix())}; "
                + f"FEED_FILE={shlex.quote(feed.as_posix())}; "
                + "DISTRO_ID=openwrt; "
                + "prepare_temporary_feed && exit 30; "
                + 'cmp -s "$FEED_FILE" "$FEED_BACKUP"'
            )
            result = self.run_sh(command)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(feed.read_text(encoding="utf-8"), original)

    def test_failed_dependency_update_uses_mirror_then_restores(self) -> None:
        with tempfile.TemporaryDirectory(
            prefix=".installer-contract-", dir=ROOT
        ) as temp_name:
            temp = Path(temp_name)
            feed = temp / "distfeeds.conf"
            snapshot = temp / "update-sees.conf"
            original = (
                "https://downloads.immortalwrt.org/snapshots/base/packages.adb\n"
                "https://packages.example.test/custom/packages.adb\n"
            )
            feed.write_text(original, encoding="utf-8", newline="\n")
            command = (
                self.source_command(LIGHT)
                + "log_info() { :; }; log_ok() { :; }; "
                + f"TMP_DIR={shlex.quote(temp.as_posix())}; "
                + f"FEED_FILE={shlex.quote(feed.as_posix())}; "
                + f"SNAPSHOT={shlex.quote(snapshot.as_posix())}; "
                + "DISTRO_ID=immortalwrt; PKG_MGR=apk; DEPENDENCIES=x; "
                + 'package_update() { cp "$FEED_FILE" "$SNAPSHOT"; return 1; }; '
                + "package_install_dependencies() { exit 90; }; "
                + "install_dependencies && exit 31; "
                + 'cmp -s "$FEED_FILE" "$FEED_BACKUP" || exit 32; '
                + 'grep -Fq "https://mirror.nju.edu.cn/immortalwrt" "$SNAPSHOT"'
            )
            result = self.run_sh(command)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(feed.read_text(encoding="utf-8"), original)

    def test_cpu_architecture_coverage_self_check(self) -> None:
        result = subprocess.run(
            ["sh", str(CPU_CHECK), "--self-check"],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("self-check passed", result.stdout)


if __name__ == "__main__":
    unittest.main()
