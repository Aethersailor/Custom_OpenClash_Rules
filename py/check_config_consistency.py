#!/usr/bin/env python3
"""Validate shared behavior across published INI and YAML configurations."""

from __future__ import annotations

import argparse
import re
from pathlib import Path
from typing import Iterable

from config_contract import (
    ACTIVE_INI_CONFIGS,
    ACTIVE_YAML_CONFIGS,
    BUILTIN_POLICIES,
    DERIVED_CONFIGS,
    FALLBACK_POLICY_MAP,
    INI_PROFILE_PAIRS,
    INI_TO_YAML_PROFILES,
    REQUIRED_RULES,
    RULESET_INTERVAL_SECONDS,
    YAML_PROFILE_PAIRS,
)

REPOSITORY_ROOT = Path(__file__).resolve().parent.parent
INI_REMOTE_INTERVAL_RE = re.compile(r",(?P<interval>\d+)$")
YAML_GROUP_RE = re.compile(r'^  - name:\s*["\']?(.*?)["\']?\s*$')
YAML_PROVIDER_RE = re.compile(r"^  ([^:#]+):\s*$")
YAML_PROVIDER_PROPERTY_RE = re.compile(r"^    ([\w-]+):\s*(.*?)\s*$")


def read_lines(root: Path, relative: str) -> list[str]:
    return (root / relative).read_text(encoding="utf-8-sig").splitlines()


def strip_yaml_scalar(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {'"', "'"}:
        return value[1:-1]
    return value


def yaml_section(lines: list[str], name: str) -> list[str]:
    marker = f"{name}:"
    try:
        start = lines.index(marker) + 1
    except ValueError:
        return []

    section: list[str] = []
    for line in lines[start:]:
        if line and not line.startswith((" ", "#")):
            break
        section.append(line)
    return section


def parse_ini_rules(lines: Iterable[str]) -> list[str]:
    prefix = "ruleset="
    return [line[len(prefix) :] for line in lines if line.startswith(prefix)]


def parse_ini_groups(lines: Iterable[str]) -> set[str]:
    prefix = "custom_proxy_group="
    return {
        line[len(prefix) :].split("`", 1)[0]
        for line in lines
        if line.startswith(prefix)
    }


def parse_yaml_rules(lines: list[str]) -> list[str]:
    rules: list[str] = []
    for line in yaml_section(lines, "rules"):
        stripped = line.strip()
        if not stripped.startswith("- "):
            continue
        rules.append(strip_yaml_scalar(stripped[2:]))
    return rules


def parse_yaml_groups(lines: list[str]) -> set[str]:
    groups: set[str] = set()
    for line in yaml_section(lines, "proxy-groups"):
        match = YAML_GROUP_RE.match(line)
        if match:
            groups.add(match.group(1))
    return groups


def parse_yaml_rule_providers(lines: list[str]) -> dict[str, dict[str, str]]:
    providers: dict[str, dict[str, str]] = {}
    current: dict[str, str] | None = None
    for line in yaml_section(lines, "rule-providers"):
        provider_match = YAML_PROVIDER_RE.match(line)
        if provider_match:
            current = providers.setdefault(provider_match.group(1), {})
            continue
        property_match = YAML_PROVIDER_PROPERTY_RE.match(line)
        if current is not None and property_match:
            current[property_match.group(1)] = strip_yaml_scalar(property_match.group(2))
    return providers


def normalize_fallback_policy(rule: str) -> str:
    for fallback, normal in FALLBACK_POLICY_MAP.items():
        rule = rule.replace(fallback, normal)
    return rule


def ini_rule_target(rule: str) -> str:
    return rule.split(",", 1)[0]


def yaml_rule_target(rule: str) -> str:
    parts = [part.strip() for part in rule.split(",")]
    if parts and parts[-1] == "no-resolve":
        parts.pop()
    return parts[-1] if parts else ""


def compare_rule_order(
    normal_path: str,
    normal_rules: list[str],
    fallback_path: str,
    fallback_rules: list[str],
) -> list[str]:
    expected = [normalize_fallback_policy(rule) for rule in normal_rules]
    actual = [normalize_fallback_policy(rule) for rule in fallback_rules]
    if expected == actual:
        return []

    errors = [
        f"{fallback_path}: rule order/content differs from {normal_path} "
        f"({len(actual)} rules versus {len(expected)})"
    ]
    for index, (wanted, found) in enumerate(zip(expected, actual), start=1):
        if wanted != found:
            errors.append(
                f"{fallback_path}: rule #{index} should be {wanted!r}, found {found!r}"
            )
            if len(errors) >= 6:
                break
    if len(expected) != len(actual) and len(errors) < 6:
        errors.append(f"{fallback_path}: rule count must match {normal_path}")
    return errors


def check_rule_targets(
    relative: str,
    rules: Iterable[str],
    groups: set[str],
    target_parser,
) -> list[str]:
    errors: list[str] = []
    for rule in rules:
        target = target_parser(rule)
        if target not in groups and target not in BUILTIN_POLICIES:
            errors.append(f"{relative}: rule target {target!r} has no matching proxy group")
    return errors


def check_ini_intervals(root: Path, paths: Iterable[str]) -> list[str]:
    errors: list[str] = []
    for relative in paths:
        for line_number, rule in enumerate(read_lines(root, relative), start=1):
            if not rule.startswith("ruleset=") or "://" not in rule:
                continue
            match = INI_REMOTE_INTERVAL_RE.search(rule)
            if not match:
                errors.append(f"{relative}:{line_number}: remote ruleset has no numeric interval")
                continue
            interval = int(match.group("interval"))
            if interval != RULESET_INTERVAL_SECONDS:
                errors.append(
                    f"{relative}:{line_number}: remote ruleset interval is {interval}; "
                    f"expected {RULESET_INTERVAL_SECONDS} seconds"
                )
    return errors


def check_yaml_providers(root: Path, paths: Iterable[str]) -> list[str]:
    errors: list[str] = []
    for relative in paths:
        providers = parse_yaml_rule_providers(read_lines(root, relative))
        for name, properties in providers.items():
            interval = properties.get("interval")
            if interval != str(RULESET_INTERVAL_SECONDS):
                errors.append(
                    f"{relative}: rule provider {name!r} interval is {interval!r}; "
                    f"expected {RULESET_INTERVAL_SECONDS} seconds"
                )
            if properties.get("behavior") == "domain":
                if properties.get("format") != "mrs":
                    errors.append(f"{relative}: domain provider {name!r} must use MRS format")
                if not properties.get("url", "").endswith(".mrs"):
                    errors.append(f"{relative}: domain provider {name!r} URL must end in .mrs")
    return errors


def check_required_rules(root: Path) -> list[str]:
    errors: list[str] = []
    for relative, required in REQUIRED_RULES.items():
        lines = read_lines(root, relative)
        rules = parse_ini_rules(lines) if relative.endswith(".ini") else parse_yaml_rules(lines)
        for rule in required:
            if rule not in rules:
                errors.append(f"{relative}: required rule is missing: {rule}")
    return errors


def check_derived_configs(root: Path) -> list[str]:
    errors: list[str] = []
    for source, derived in DERIVED_CONFIGS:
        source_text = (root / source).read_text(encoding="utf-8-sig")
        derived_text = (root / derived).read_text(encoding="utf-8-sig")
        if source_text != derived_text:
            errors.append(
                f"{derived}: generated compatibility file differs from {source}; "
                "run python py/check_config_consistency.py --sync"
            )
    return errors


def sync_derived_configs(root: Path) -> list[str]:
    updated: list[str] = []
    for source, derived in DERIVED_CONFIGS:
        source_bytes = (root / source).read_bytes()
        destination = root / derived
        if destination.read_bytes() != source_bytes:
            destination.write_bytes(source_bytes)
            updated.append(derived)
    return updated


def validate_repository(root: Path = REPOSITORY_ROOT) -> list[str]:
    errors: list[str] = []
    errors.extend(check_ini_intervals(root, ACTIVE_INI_CONFIGS))
    errors.extend(check_yaml_providers(root, ACTIVE_YAML_CONFIGS))

    for normal, fallback in INI_PROFILE_PAIRS:
        normal_lines = read_lines(root, normal)
        fallback_lines = read_lines(root, fallback)
        normal_rules = parse_ini_rules(normal_lines)
        fallback_rules = parse_ini_rules(fallback_lines)
        errors.extend(compare_rule_order(normal, normal_rules, fallback, fallback_rules))

    for normal, fallback in YAML_PROFILE_PAIRS:
        normal_lines = read_lines(root, normal)
        fallback_lines = read_lines(root, fallback)
        normal_rules = parse_yaml_rules(normal_lines)
        fallback_rules = parse_yaml_rules(fallback_lines)
        errors.extend(compare_rule_order(normal, normal_rules, fallback, fallback_rules))
        normal_providers = parse_yaml_rule_providers(normal_lines)
        fallback_providers = parse_yaml_rule_providers(fallback_lines)
        if normal_providers != fallback_providers:
            errors.append(
                f"{fallback}: rule-provider definitions differ from {normal}"
            )

    for relative in ACTIVE_INI_CONFIGS:
        lines = read_lines(root, relative)
        errors.extend(
            check_rule_targets(
                relative,
                parse_ini_rules(lines),
                parse_ini_groups(lines),
                ini_rule_target,
            )
        )

    for relative in ACTIVE_YAML_CONFIGS:
        lines = read_lines(root, relative)
        errors.extend(
            check_rule_targets(
                relative,
                parse_yaml_rules(lines),
                parse_yaml_groups(lines),
                yaml_rule_target,
            )
        )

    for ini_path, yaml_path in INI_TO_YAML_PROFILES:
        ini_targets = {
            ini_rule_target(rule) for rule in parse_ini_rules(read_lines(root, ini_path))
        }
        yaml_targets = {
            yaml_rule_target(rule) for rule in parse_yaml_rules(read_lines(root, yaml_path))
        }
        if ini_targets != yaml_targets:
            errors.append(
                f"{ini_path} and {yaml_path}: routed policy sets differ; "
                f"INI-only={sorted(ini_targets - yaml_targets)!r}, "
                f"YAML-only={sorted(yaml_targets - ini_targets)!r}"
            )

    errors.extend(check_required_rules(root))
    errors.extend(check_derived_configs(root))
    return errors


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--check", action="store_true", help="validate without changing files")
    mode.add_argument("--sync", action="store_true", help="refresh generated compatibility files")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.sync:
        updated = sync_derived_configs(REPOSITORY_ROOT)
        for relative in updated:
            print(f"[SYNC] {relative}")

    errors = validate_repository(REPOSITORY_ROOT)
    if errors:
        for error in errors:
            print(f"[ERROR] {error}")
        return 1

    print("[OK] Published configuration contract is consistent.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
