#!/usr/bin/env python3
"""Synchronize shared helpers while keeping both public installers standalone."""

from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
LIGHT_INSTALLER = ROOT / "shell" / "install_openclash_dev.sh"
FULL_INSTALLER = ROOT / "shell" / "install_openclash_dev_update.sh"

# The full installer is canonical for every helper used by both entrypoints.
SHARED_FUNCTIONS = {
    "init_terminal",
    "append_log",
    "print_line",
    "print_step",
    "ui_field",
    "log_info",
    "log_warn",
    "log_error",
    "log_ok",
    "log_skip",
    "run_logged",
    "show_log_excerpt",
    "print_failure_summary",
    "die",
    "logo",
    "restore_feed",
    "cleanup",
    "init_runtime",
    "detect_distribution",
    "detect_environment",
    "select_feed_file",
    "rewrite_feed_to_mirror",
    "prepare_temporary_feed",
    "package_update",
    "package_install_dependencies",
    "install_dependencies",
    "check_required_commands",
    "curl_download",
    "file_size_bytes",
    "file_sha256",
    "base64_sha256_to_hex",
    "parse_jsdelivr_package_metadata",
    "fetch_package_integrity_metadata",
    "fetch_package_refs_route",
    "fetch_package_branch_sha",
    "download_commit_file",
    "parse_package_version",
    "package_file_name",
    "apk_supports_allow_downgrade",
    "verify_package_file",
    "download_openclash_package",
    "normalize_version",
    "get_installed_version",
    "install_openclash_package",
    "preserve_failed_package",
    "install_latest_openclash_package",
    "has_cpu_flag",
    "has_all_cpu_flags",
    "detect_mips_float",
    "detect_loongarch_abi",
    "detect_core_arch",
    "get_effective_core_type",
    "configure_base_uci",
    "run_core_update",
    "enable_and_restart_openclash",
}


@dataclass(frozen=True)
class ShellFunction:
    name: str
    start: int
    end: int
    content: str


def extract_functions(content: str) -> dict[str, ShellFunction]:
    starts = list(re.finditer(r"(?m)^([A-Za-z_][A-Za-z0-9_]*)\(\) \{\n", content))
    functions: dict[str, ShellFunction] = {}
    for index, match in enumerate(starts):
        end = starts[index + 1].start() if index + 1 < len(starts) else len(content)
        functions[match.group(1)] = ShellFunction(
            name=match.group(1),
            start=match.start(),
            end=end,
            content=content[match.start() : end].rstrip() + "\n\n",
        )
    return functions


def synchronized_light_content(light: str, full: str) -> str:
    light_functions = extract_functions(light)
    full_functions = extract_functions(full)
    missing = (SHARED_FUNCTIONS - light_functions.keys()) | (
        SHARED_FUNCTIONS - full_functions.keys()
    )
    if missing:
        raise ValueError(f"missing shared installer functions: {sorted(missing)}")

    replacements = sorted(
        (
            (light_functions[name], full_functions[name].content)
            for name in SHARED_FUNCTIONS
        ),
        key=lambda item: item[0].start,
        reverse=True,
    )
    for target, replacement in replacements:
        light = light[: target.start] + replacement + light[target.end :]
    return light


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--check", action="store_true", help="verify without modifying files"
    )
    args = parser.parse_args()

    light = LIGHT_INSTALLER.read_text(encoding="utf-8")
    full = FULL_INSTALLER.read_text(encoding="utf-8")
    synchronized = synchronized_light_content(light, full)
    if synchronized == light:
        print("Shared installer helpers are synchronized.")
        return 0
    if args.check:
        print("ERROR: lightweight installer has stale shared helper implementations.")
        return 1
    LIGHT_INSTALLER.write_text(synchronized, encoding="utf-8", newline="\n")
    print(f"Updated shared helpers in {LIGHT_INSTALLER}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
