from __future__ import annotations

import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OVERWRITE_ROOT = ROOT / "overwrite"

ALLOWED_HELPERS = {
    "ruby_arr_add_file",
    "ruby_arr_edit",
    "ruby_arr_head_add_file",
    "ruby_arr_insert",
    "ruby_arr_insert_arr",
    "ruby_arr_insert_hash",
    "ruby_cover",
    "ruby_delete",
    "ruby_edit",
    "ruby_map_edit",
    "ruby_merge",
    "ruby_merge_hash",
    "ruby_uniq",
}

FORBIDDEN_TOKENS = (
    "#{",
    "system",
    "exec",
    "eval",
    "require",
    "spawn",
    "popen",
    "fork",
    "Kernel",
    "Process",
    "Open3",
    "Marshal",
    "Fiddle",
    "syscall",
    "const_get",
    "__send__",
    "instance_eval",
    "class_eval",
    "module_eval",
    "%x",
    "IO.",
    "File.",
    "Dir.",
    "ENV",
)

SECTION_PATTERN = re.compile(r"^\[([A-Za-z0-9_-]+)\]$")
VARIABLE_PATTERN = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")


def active_modules() -> list[Path]:
    modules: list[Path] = []
    for path in OVERWRITE_ROOT.rglob("*.conf"):
        relative_parts = path.relative_to(OVERWRITE_ROOT).parts
        if relative_parts[0] in {"archived", "OpenClash_Overwrite"}:
            continue
        modules.append(path)
    return sorted(modules)


def overwrite_commands(path: Path) -> list[str]:
    section = ""
    commands: list[str] = []
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        stripped = raw_line.strip()
        section_match = SECTION_PATTERN.fullmatch(stripped)
        if section_match:
            section = section_match.group(1)
            continue
        if not stripped or stripped.startswith(("#", ";")):
            continue
        if section == "Overwrite":
            commands.append(stripped)
    return commands


def validate_variable(value: str, index: int) -> int:
    following = value[index + 1 :]
    if following.startswith("("):
        raise ValueError("command substitution is not allowed")
    if following.startswith("{"):
        closing = following.find("}")
        if closing < 0:
            raise ValueError("unterminated variable expansion")
        name = following[1:closing]
        if not VARIABLE_PATTERN.fullmatch(name):
            raise ValueError("invalid variable expansion")
        return index + closing + 2
    match = VARIABLE_PATTERN.match(following)
    if match:
        return index + 1 + len(match.group(0))
    return index + 1


def validate_overwrite_command(command: str) -> None:
    helper, separator, remainder = command.partition(" ")
    if not separator or helper not in ALLOWED_HELPERS:
        raise ValueError("command must call one allowed helper")

    index = 0
    argument_count = 0
    while index < len(remainder):
        while index < len(remainder) and remainder[index].isspace():
            index += 1
        if index == len(remainder):
            break
        quote = remainder[index]
        if quote not in {'"', "'"}:
            raise ValueError("arguments must be quoted literals")
        index += 1
        value_chars: list[str] = []
        while index < len(remainder) and remainder[index] != quote:
            character = remainder[index]
            if character in {"`", "\\", ";"}:
                raise ValueError(f"forbidden character {character!r}")
            if character == "$" and quote == '"':
                next_index = validate_variable(remainder, index)
                value_chars.append(remainder[index:next_index])
                index = next_index
                continue
            value_chars.append(character)
            index += 1
        if index >= len(remainder):
            raise ValueError("unterminated quoted argument")
        value = "".join(value_chars)
        for token in FORBIDDEN_TOKENS:
            if token in value:
                raise ValueError(f"forbidden token {token!r}")
        index += 1
        argument_count += 1

    if argument_count == 0:
        raise ValueError("helper call has no arguments")


class OpenClashOverwriteCompatibilityTests(unittest.TestCase):
    def test_active_module_inventory(self) -> None:
        relative_paths = {path.relative_to(ROOT).as_posix() for path in active_modules()}
        self.assertIn("overwrite/Add_No_Resolve.conf", relative_paths)
        self.assertIn("overwrite/Rule_Provider_Format_Fix.conf", relative_paths)
        self.assertNotIn("overwrite/Use_LuCI_DNS_Only.conf", relative_paths)
        self.assertEqual(len(relative_paths), 24)

    def test_all_dynamic_commands_match_current_openclash_contract(self) -> None:
        failures: list[str] = []
        for path in active_modules():
            for command in overwrite_commands(path):
                try:
                    validate_overwrite_command(command)
                except ValueError as error:
                    failures.append(f"{path.relative_to(ROOT)}: {error}")
        self.assertEqual(failures, [])

    def test_validator_accepts_minimal_safe_command(self) -> None:
        validate_overwrite_command('ruby_edit "$CONFIG_FILE" "[\'rules\']" "true"')

    def test_validator_rejects_old_inline_script_shape(self) -> None:
        for command in (
            'ruby_edit "$CONFIG_FILE" "[\'rules\']" "begin; true; end"',
            'ruby_edit "$CONFIG_FILE" "[\'rules\']" "ENV[\'TOKEN\']"',
            'ruby_edit "$CONFIG_FILE" "[\'rules\']" "$(id)"',
            'ruby_edit "$CONFIG_FILE" "[\'rules\']" true',
        ):
            with self.subTest(command=command), self.assertRaises(ValueError):
                validate_overwrite_command(command)


if __name__ == "__main__":
    unittest.main()
