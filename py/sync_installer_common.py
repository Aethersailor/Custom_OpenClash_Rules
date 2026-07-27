#!/usr/bin/env python3
"""Keep shared installer helpers synchronized while publishing standalone scripts."""

from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
LIGHT_INSTALLER = ROOT / "shell" / "install_openclash_dev.sh"
FULL_INSTALLER = ROOT / "shell" / "install_openclash_dev_update.sh"

# The full installer is canonical for helpers whose behavior is intentionally
# identical. The lightweight file embeds synchronized copies so its public
# curl | sh entrypoint remains self-contained.
SHARED_FUNCTIONS = {
    "print_line",
    "print_step",
    "log_info",
    "log_warn",
    "log_error",
    "log_ok",
    "die",
    "restore_feed",
    "detect_environment",
    "package_update",
    "package_install_dependencies",
    "set_feed_file",
    "enable_temporary_nju_mirror",
    "fetch_package_metadata",
    "parse_package_metadata",
    "parse_package_version",
    "resolve_package_metadata",
    "verify_file_size",
    "verify_sha256_base64",
    "verify_package_file",
    "prepare_latest_package",
    "install_openclash_package",
    "extract_version_from_filename",
    "normalize_version",
    "has_cpu_flag",
    "has_all_cpu_flags",
    "detect_mips_float",
    "detect_loongarch_abi",
    "get_effective_core_type",
    "get_core_path",
    "verify_core_version",
    "update_core",
    "start_openclash",
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
        [
            (light_functions[name], full_functions[name].content)
            for name in SHARED_FUNCTIONS
        ],
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
