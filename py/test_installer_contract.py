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
            encoding="utf-8",
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
                    encoding="utf-8",
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
        expected_call = 'run_logged "$core_script" "$core_type"'
        invalid_prefix_argument = (
            '"$core_script" "$core_type" "https://testingcf.jsdelivr.net/"'
        )
        for path, content in ((LIGHT, self.light), (FULL, self.full)):
            with self.subTest(path=path.name):
                self.assertIn(expected_call, content)
                self.assertNotIn(invalid_prefix_argument, content)

    def test_default_ui_is_the_only_user_mode(self) -> None:
        self.assertIn('INSTALLER_TITLE="OpenClash Dev 插件与内核更新"', self.light)
        self.assertIn('INSTALLER_TITLE="OpenClash Dev 完整更新"', self.full)
        self.assertIn("TOTAL_STEPS=5", self.light)
        self.assertIn("TOTAL_STEPS=7", self.full)
        common_details = (
            "发行版",
            "包管理器",
            "防火墙",
            "临时镜像",
            "固定提交",
            "目标版本",
            "安装包",
            "下载来源",
            "完整性检查",
            "CPU / 内核架构",
            "OpenClash 详细日志",
            "本次运行日志",
        )
        for path, content in ((LIGHT, self.light), (FULL, self.full)):
            with self.subTest(path=path.name):
                self.assertIn("[ -t 1 ]", content)
                self.assertIn("clear 2>/dev/null", content)
                self.assertNotIn("--verbose", content)
                self.assertNotIn("--quiet", content)
                self.assertNotIn("--no-color", content)
                for detail in common_details:
                    self.assertIn(detail, content)
        full_details = (
            "Smart 设置",
            "LightGBM",
            "Geo / Chnroute / 订阅",
            "用户预设",
        )
        for detail in full_details:
            self.assertIn(detail, self.full)

    def test_non_interactive_ui_has_no_ansi_or_clear_output(self) -> None:
        result = self.run_sh(
            self.source_command(LIGHT)
            + "logo; print_step 1 '检测设备环境'; "
            + "ui_field '发行版' 'OpenWrt'; log_ok '当前设备环境受支持。'"
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("\x1b", result.stdout)
        self.assertNotIn("CLEAR_CALLED", result.stdout)
        self.assertIn("OpenClash Dev 插件与内核更新", result.stdout)
        self.assertIn("[1/5] 检测设备环境", result.stdout)
        self.assertIn("发行版：OpenWrt", result.stdout)

    def _render_successful_main(self, path: Path, *, full: bool) -> str:
        stubs = (
            "init_terminal() { :; }; "
            "init_runtime() { : >\"$INSTALLER_LOG\"; }; "
            "detect_environment() { "
            "ui_field '发行版' 'OpenWrt'; ui_field '包管理器' 'apk'; "
            "ui_field '防火墙' 'nftables'; ui_field '安装包格式' 'APK'; "
            "log_ok '当前设备环境受支持。'; }; "
            "install_dependencies() { FEED_RESTORE_RESULT='已恢复为运行前状态'; "
            "ui_field '临时镜像' '测试镜像'; ui_field '原软件源' \"$FEED_RESTORE_RESULT\"; "
            "log_ok 'OpenClash 运行环境已准备完成。'; }; "
            "check_required_commands() { :; }; "
            "install_latest_openclash_package() { TARGET_VERSION='0.47.999'; "
            "PACKAGE_SOURCE='jsDelivr'; ui_field '目标版本' \"$TARGET_VERSION\"; "
            "ui_field '下载来源' \"$PACKAGE_SOURCE\"; "
            "log_ok 'OpenClash 0.47.999 已安装并完成版本确认。'; }; "
            "configure_base_uci() { DETECTED_ARCH='linux-amd64-v3'; "
            "ui_field 'CPU / 内核架构' \"$DETECTED_ARCH\"; }; "
            "run_core_update() { CORE_TYPE_USED='Smart'; "
            "CORE_RESULT='内置更新流程已执行'; "
            "ui_field '内核类型' \"$CORE_TYPE_USED\"; "
            "log_ok '内核更新流程已交由 OpenClash 处理。'; }; "
            "enable_and_restart_openclash() { SERVICE_RESULT='已启用并执行重启'; "
            "ui_field '服务操作' '已执行重启'; "
            "log_ok 'OpenClash 启用和重启命令执行完成。'; }; "
        )
        if full:
            stubs += (
                "configure_smart_features() { SMART_RESULT='自动切换已启用'; "
                "ui_field '自动切换' '已启用'; }; "
                "update_smart_model() { MODEL_RESULT='Model-large.bin 已更新'; "
                "ui_field '模型选择' 'Model-large.bin'; "
                "log_ok 'LightGBM 模型已安全更新。'; }; "
                "run_full_resource_updates() { "
                "RESOURCE_RESULT='Geo、地区列表和订阅流程已执行'; "
                "PRESET_RESULT='未检测到，已跳过'; "
                "ui_field 'Geo 数据库' '已调用 OpenClash 内置更新流程'; "
                "log_ok 'OpenClash 相关资源更新流程均已执行。'; }; "
            )
        with tempfile.TemporaryDirectory(
            prefix=".installer-ui-", dir=ROOT
        ) as temp_name:
            log_file = Path(temp_name) / "installer.log"
            result = self.run_sh(
                self.source_command(path)
                + f"INSTALLER_LOG={shlex.quote(log_file.as_posix())}; "
                + stubs
                + "main"
            )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("\x1b", result.stdout)
        self.assertNotIn("https://", result.stdout)
        self.assertNotIn("################################################################", result.stdout)
        return result.stdout

    def test_light_success_output_has_five_steps_and_summary(self) -> None:
        output = self._render_successful_main(LIGHT, full=False)
        self.assertIn("[1/5] 检测设备环境", output)
        self.assertIn("[5/5] 启用并重启 OpenClash", output)
        self.assertIn("OpenClash 插件：0.47.999，安装并验证成功", output)
        self.assertIn("内核：Smart，内置更新流程已执行", output)

    def test_full_success_output_has_seven_steps_and_detailed_summary(self) -> None:
        output = self._render_successful_main(FULL, full=True)
        self.assertIn("[1/7] 检测设备环境", output)
        self.assertIn("[7/7] 启用并重启 OpenClash", output)
        self.assertIn("LightGBM：Model-large.bin 已更新", output)
        self.assertIn("Geo / Chnroute / 订阅：Geo、地区列表和订阅流程已执行", output)

    def test_failure_automatically_expands_context_and_log_excerpt(self) -> None:
        with tempfile.TemporaryDirectory(
            prefix=".installer-ui-", dir=ROOT
        ) as temp_name:
            log_file = Path(temp_name) / "installer.log"
            command = (
                self.source_command(LIGHT)
                + f"INSTALLER_LOG={shlex.quote(log_file.as_posix())}; "
                + ": >\"$INSTALLER_LOG\"; CURRENT_STAGE='获取并安装 OpenClash 插件'; "
                + "printf '%s\\n' 'curl: connection timed out' >>\"$INSTALLER_LOG\"; "
                + "die '所有下载来源均未获得有效安装包。'"
            )
            result = self.run_sh(command)
        self.assertEqual(result.returncode, 1)
        self.assertIn("更新未完成", result.stderr)
        self.assertIn("失败阶段：获取并安装 OpenClash 插件", result.stderr)
        self.assertIn("所有下载来源均未获得有效安装包", result.stderr)
        self.assertIn("curl: connection timed out", result.stderr)
        self.assertIn("检查网络后重新运行同一条安装命令", result.stderr)

    def test_external_command_output_is_logged_instead_of_flooding_terminal(self) -> None:
        with tempfile.TemporaryDirectory(
            prefix=".installer-ui-", dir=ROOT
        ) as temp_name:
            log_file = Path(temp_name) / "installer.log"
            command = (
                self.source_command(LIGHT)
                + f"INSTALLER_LOG={shlex.quote(log_file.as_posix())}; "
                + ": >\"$INSTALLER_LOG\"; "
                + "run_logged sh -c 'printf raw-package-manager-output'; "
                + "log_ok '依赖处理完成。'"
            )
            result = self.run_sh(command)
            logged = log_file.read_text(encoding="utf-8")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("raw-package-manager-output", result.stdout)
        self.assertIn("依赖处理完成", result.stdout)
        self.assertIn("raw-package-manager-output", logged)

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
            encoding="utf-8",
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("self-check passed", result.stdout)


if __name__ == "__main__":
    unittest.main()
