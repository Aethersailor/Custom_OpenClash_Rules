#!/usr/bin/env python3
"""Generate Stash-specific subconverter templates from maintained Clash policy."""

from __future__ import annotations

import argparse
from pathlib import Path
from urllib.parse import urlsplit, urlunsplit


TEMPLATE_PAIRS = (
    ("Custom_Clash.ini", "Custom_Stash.ini"),
    ("Custom_Clash_Fallback.ini", "Custom_Stash_Fallback.ini"),
    ("Custom_Clash_Lite.ini", "Custom_Stash_Lite.ini"),
    ("Custom_Clash_Lite_Fallback.ini", "Custom_Stash_Lite_Fallback.ini"),
    ("Custom_Clash_GFW.ini", "Custom_Stash_GFW.ini"),
    ("Custom_Clash_GFW_Fallback.ini", "Custom_Stash_GFW_Fallback.ini"),
    ("Custom_Clash_Full.ini", "Custom_Stash_Full.ini"),
    ("Custom_Clash_Full_Fallback.ini", "Custom_Stash_Full_Fallback.ini"),
    ("Custom_Clash.ini", "Custom_Stash_Mainland.ini"),
)

EXPECTED_PROVIDER_COUNTS = {
    "Custom_Stash.ini": 13,
    "Custom_Stash_Fallback.ini": 13,
    "Custom_Stash_Lite.ini": 9,
    "Custom_Stash_Lite_Fallback.ini": 9,
    "Custom_Stash_GFW.ini": 3,
    "Custom_Stash_GFW_Fallback.ini": 3,
    "Custom_Stash_Full.ini": 13,
    "Custom_Stash_Full_Fallback.ini": 13,
    "Custom_Stash_Mainland.ini": 13,
}

META_GEOIP_URL = (
    "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/"
    "meta/geo/geoip/{name}.mrs"
)
STASH_GEOIP_PROVIDERS = frozenset(
    {"private", "telegram", "twitter", "facebook", "google", "netflix"}
)
STASH_EXPLICITLY_UNSUPPORTED = {
    "SRC-PORT,41641": (
        "Stash source-port matching is available only through SCRIPT in gateway mode"
    ),
}

DIRECT_SOURCE_PASSTHROUGH_TYPES = frozenset(
    {"DOMAIN", "DOMAIN-SUFFIX", "DOMAIN-KEYWORD", "DOMAIN-REGEX", "IP-CIDR", "IP-CIDR6"}
)
SUPPORTED_SETTINGS = frozenset(
    {"enable_rule_generator=true", "overwrite_original_rules=true"}
)
BENCHMARK_URL = "https://cp.cloudflare.com/generate_204"
SELECT_PSEUDO_URL = "http://wifi.vivo.com.cn/generate_204"
STASH_BUILTIN_POLICIES = frozenset({"DIRECT", "REJECT", "REJECT-DROP", "PASS"})

# Every classical source is deliberately enumerated. A new source must choose an
# equivalent Stash provider type or fail generation instead of leaking through.
CLASSICAL_PROJECTIONS = {
    "Custom_Direct_Classical_IP.yaml": (
        ("clash-ipcidr", "Custom_Direct_IP.mrs", True),
    ),
    "Custom_Proxy_Classical_IP.yaml": (
        ("clash-ipcidr", "Custom_Proxy_IP.mrs", True),
    ),
    "Steam_CDN_Classical_IP.yaml": (
        ("clash-ipcidr", "Steam_CDN_IP.mrs", True),
    ),
    "Game_Download_CDN_Classical_IP.yaml": (
        ("clash-ipcidr", "Game_Download_CDN_IP.mrs", True),
    ),
    "Steam_CDN_Classical.yaml": (
        ("clash-domain", "Steam_CDN_Domain.mrs", False),
        ("clash-ipcidr", "Steam_CDN_IP.mrs", True),
    ),
    "Custom_Port_Direct.yaml": (
        ("clash-classic", "Custom_Port_Direct.yaml", False),
    ),
}

GENERATED_HEADER = (
    "; 此文件由 py/generate_stash_configs.py 生成，请勿直接修改。\n"
    "; 策略来源：{source}\n"
    "; Stash 兼容边界：非国家 GEOIP 已映射为 MRS；SRC-PORT,41641 因仅网关 SCRIPT\n"
    "; 可实现而被显式排除；策略组仅保留 interval，不输出无等价语义的组级 URL、\n"
    "; timeout 与 tolerance；复杂排除正则使用可移植的全节点回退或已有自动组。\n"
)


def _replace_url_name(url: str, name: str) -> str:
    parsed = urlsplit(url)
    if not parsed.scheme or not parsed.netloc or "/" not in parsed.path:
        raise ValueError(f"unsupported ruleset URL: {url}")
    path = parsed.path.rsplit("/", 1)[0] + "/" + name
    return urlunsplit((parsed.scheme, parsed.netloc, path, parsed.query, parsed.fragment))


def extract_direct_port_rules(text: str) -> tuple[tuple[str, ...], tuple[str, ...]]:
    """Return supported destination-port rules and explicitly omitted rules."""
    destination_ports: list[str] = []
    omitted: list[str] = []
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        rule_type = line.split(",", 1)[0]
        if rule_type in DIRECT_SOURCE_PASSTHROUGH_TYPES:
            continue
        if rule_type == "DST-PORT":
            destination_ports.append(line)
            continue
        if line in STASH_EXPLICITLY_UNSUPPORTED:
            omitted.append(line)
            continue
        raise ValueError(f"unmapped Stash rule in rule/Custom_Direct.list: {line}")

    if set(omitted) != set(STASH_EXPLICITLY_UNSUPPORTED):
        missing = sorted(set(STASH_EXPLICITLY_UNSUPPORTED) - set(omitted))
        raise ValueError(f"stale or missing explicit Stash exclusions: {missing}")
    return tuple(destination_ports), tuple(omitted)


def _remote_ruleset(
    policy: str,
    provider_type: str,
    url: str,
    interval: str,
    *,
    no_resolve: bool,
) -> str:
    options = interval + ("|no-resolve" if no_resolve else "")
    return f"ruleset={policy},{provider_type}:{url},{options}"


def project_ruleset_line(line: str, direct_source: str) -> tuple[str, ...]:
    payload = line.removeprefix("ruleset=")
    if payload == line or "," not in payload:
        raise ValueError(f"invalid ruleset line: {line}")
    policy, specification = payload.split(",", 1)
    if not policy or not specification:
        raise ValueError(f"invalid ruleset line: {line}")

    if specification.startswith("[]"):
        fields = specification[2:].split(",")
        rule_type = fields[0]
        if rule_type == "GEOSITE":
            if len(fields) != 2 or not fields[1]:
                raise ValueError(f"unsupported inline GEOSITE rule: {line}")
            return (line,)
        if rule_type == "FINAL":
            if fields != ["FINAL"]:
                raise ValueError(f"unsupported inline FINAL rule: {line}")
            return (line,)
        if rule_type == "GEOIP":
            if len(fields) != 3 or fields[2] != "no-resolve":
                raise ValueError(f"unsupported inline GEOIP options: {line}")
            name = fields[1]
            if name == "cn":
                return (line,)
            if name not in STASH_GEOIP_PROVIDERS:
                raise ValueError(f"unmapped non-country GEOIP key: {name}")
            return (
                _remote_ruleset(
                    policy,
                    "clash-ipcidr",
                    META_GEOIP_URL.format(name=name),
                    "28800",
                    no_resolve=True,
                ),
            )
        raise ValueError(f"unsupported inline Stash ruleset: {line}")

    if "," not in specification:
        raise ValueError(f"remote ruleset interval is missing: {line}")
    typed_url, interval = specification.rsplit(",", 1)
    if not interval.isdigit() or ":" not in typed_url:
        raise ValueError(f"invalid remote ruleset: {line}")
    provider_type, url = typed_url.split(":", 1)
    source_name = urlsplit(url).path.rsplit("/", 1)[-1]

    if provider_type == "clash-domain":
        if not source_name.endswith("_Domain.mrs"):
            raise ValueError(f"unmapped clash-domain source: {source_name}")
        return (line,)
    if provider_type != "clash-classic" or source_name not in CLASSICAL_PROJECTIONS:
        raise ValueError(f"unmapped remote Stash ruleset: {line}")

    projected = tuple(
        _remote_ruleset(
            policy,
            target_type,
            _replace_url_name(url, target_name),
            interval,
            no_resolve=no_resolve,
        )
        for target_type, target_name, no_resolve in CLASSICAL_PROJECTIONS[source_name]
    )
    if source_name == "Custom_Direct_Classical_IP.yaml":
        destination_ports, _ = extract_direct_port_rules(direct_source)
        projected += tuple(f"ruleset={policy},[]{rule}" for rule in destination_ports)
    return projected


def _portable_selector(group_name: str, selector: str, has_auto_group: bool) -> str | None:
    if selector.startswith("[]"):
        return selector
    if any(ord(character) < 32 for character in selector):
        raise ValueError(f"control character in selector for {group_name}")

    if group_name == "🐢 低倍率节点":
        if "低倍率" not in selector or "(?<" not in selector:
            raise ValueError("unexpected low-multiplier selector")
        return "(低倍率|低倍)"
    if "(?!" in selector:
        if group_name == "🌐 其他地区" or not has_auto_group:
            return ".*"
        return None

    portable = selector.replace("[A-Za-z]{2,}", "[A-Za-z][A-Za-z]+")
    portable = portable.replace("|(?<!尼|-)日", "")
    portable = portable.replace("(?<!白)俄罗斯|", "")
    portable = portable.replace("(?<!白)俄|", "")
    if "(?<" in portable or "," in portable:
        raise ValueError(f"unmapped non-portable selector for {group_name}: {selector}")
    return portable


def group_dynamic_selectors(line: str) -> tuple[str, ...]:
    fields = line.split("`")
    if len(fields) < 3 or not fields[0].startswith("custom_proxy_group="):
        raise ValueError(f"invalid custom proxy group: {line}")
    group_type = fields[1]
    candidates = fields[2:] if group_type == "select" else fields[2:-2]
    return tuple(candidate for candidate in candidates if not candidate.startswith("[]"))


def validate_policy_reference_closure(rendered: str) -> None:
    group_lines = [
        line for line in rendered.splitlines() if line.startswith("custom_proxy_group=")
    ]
    group_names = [line.split("`", 1)[0].removeprefix("custom_proxy_group=") for line in group_lines]
    if (
        any(not name or name in STASH_BUILTIN_POLICIES for name in group_names)
        or len(group_names) != len(set(group_names))
    ):
        raise ValueError("reserved, duplicate, or empty Stash policy-group name")

    available = set(group_names) | set(STASH_BUILTIN_POLICIES)
    group_edges: dict[str, set[str]] = {name: set() for name in group_names}
    for line in group_lines:
        fields = line.split("`")
        group_name = fields[0].removeprefix("custom_proxy_group=")
        group_type = fields[1]
        candidates = fields[2:] if group_type == "select" else fields[2:-2]
        for candidate in candidates:
            if candidate.startswith("[]") and candidate[2:] not in available:
                raise ValueError(f"dangling Stash policy-group member: {candidate[2:]}")
            if candidate.startswith("[]") and candidate[2:] in group_edges:
                group_edges[group_name].add(candidate[2:])

    visiting: set[str] = set()
    visited: set[str] = set()

    def visit(group_name: str) -> None:
        if group_name in visiting:
            raise ValueError(f"cyclic Stash policy-group reference: {group_name}")
        if group_name in visited:
            return
        visiting.add(group_name)
        for referenced_group in group_edges[group_name]:
            visit(referenced_group)
        visiting.remove(group_name)
        visited.add(group_name)

    for group_name in group_names:
        visit(group_name)

    for line in rendered.splitlines():
        if not line.startswith("ruleset="):
            continue
        policy = line.removeprefix("ruleset=").split(",", 1)[0]
        if policy not in available:
            raise ValueError(f"dangling Stash ruleset policy: {policy}")


def project_group_line(line: str) -> str:
    fields = line.split("`")
    if len(fields) < 3 or not fields[0].startswith("custom_proxy_group="):
        raise ValueError(f"invalid custom proxy group: {line}")
    group_name = fields[0].removeprefix("custom_proxy_group=")
    group_type = fields[1]
    if group_type not in {"select", "url-test", "fallback"}:
        raise ValueError(f"unsupported Stash group type: {group_type}")

    if group_type == "select":
        candidates = fields[2:]
        unexpected_urls = [value for value in candidates if value.startswith(("http://", "https://"))]
        if unexpected_urls and unexpected_urls != [SELECT_PSEUDO_URL]:
            raise ValueError(f"unexpected select-group URL for {group_name}: {unexpected_urls}")
        candidates = [value for value in candidates if value != SELECT_PSEUDO_URL]
        suffix: list[str] = []
    else:
        if len(fields) < 5:
            raise ValueError(f"incomplete benchmark group: {line}")
        candidates = fields[2:-2]
        benchmark_url, times = fields[-2:]
        if benchmark_url != BENCHMARK_URL:
            raise ValueError(f"unexpected benchmark URL for {group_name}: {benchmark_url}")
        interval = times.split(",", 1)[0]
        if not interval.isdigit():
            raise ValueError(f"invalid benchmark interval for {group_name}: {times}")
        suffix = ["", interval]

    has_auto_group = "[]♻️ 自动选择" in candidates
    projected_candidates = []
    for candidate in candidates:
        projected = _portable_selector(group_name, candidate, has_auto_group)
        if projected is not None:
            projected_candidates.append(projected)

    dynamic_count = sum(not item.startswith("[]") for item in projected_candidates)
    if dynamic_count > 1:
        raise ValueError(f"multiple dynamic selectors are unsupported for {group_name}")
    if not projected_candidates:
        raise ValueError(f"group has no Stash candidates: {group_name}")
    return "`".join(fields[:2] + projected_candidates + suffix)


def validate_rendered(name: str, rendered: str) -> None:
    rulesets = [line for line in rendered.splitlines() if line.startswith("ruleset=")]
    providers = [line for line in rulesets if ",[]" not in line]
    if len(providers) != EXPECTED_PROVIDER_COUNTS[name]:
        raise ValueError(
            f"{name}: expected {EXPECTED_PROVIDER_COUNTS[name]} providers, got {len(providers)}"
        )
    if any("SRC-PORT" in line for line in rulesets):
        raise ValueError(f"{name}: source-port rule leaked into Stash output")
    for line in rulesets:
        if ",[]GEOIP," in line and ",[]GEOIP,cn,no-resolve" not in line:
            raise ValueError(f"{name}: non-country GEOIP was not projected: {line}")
    for line in rendered.splitlines():
        if not line.startswith("custom_proxy_group="):
            continue
        if BENCHMARK_URL in line or SELECT_PSEUDO_URL in line:
            raise ValueError(f"{name}: Clash-only group URL leaked: {line}")
        selectors = group_dynamic_selectors(line)
        if len(selectors) > 1:
            raise ValueError(f"{name}: group has multiple dynamic selectors: {line}")
        if any("," in value or "(?<" in value for value in selectors):
            raise ValueError(f"{name}: unsafe Stash selector: {line}")
    validate_policy_reference_closure(rendered)


def render_template(root: Path, source_name: str, output_name: str) -> str:
    source_path = root / "cfg" / source_name
    direct_source = (root / "rule" / "Custom_Direct.list").read_text(encoding="utf-8")
    source = source_path.read_text(encoding="utf-8")
    rendered_lines: list[str] = GENERATED_HEADER.format(source=f"cfg/{source_name}").splitlines()
    section_count = 0
    for raw_line in source.splitlines():
        line = raw_line.rstrip()
        if not line or line.startswith((";", "#")):
            rendered_lines.append(line)
        elif line == "[custom]":
            section_count += 1
            rendered_lines.append(line)
        elif line.startswith("ruleset="):
            rendered_lines.extend(project_ruleset_line(line, direct_source))
        elif line.startswith("custom_proxy_group="):
            rendered_lines.append(project_group_line(line))
        elif line in SUPPORTED_SETTINGS:
            rendered_lines.append(line)
        else:
            raise ValueError(f"unmapped line in cfg/{source_name}: {line}")
    if section_count != 1:
        raise ValueError(f"cfg/{source_name}: expected one [custom] section")

    while rendered_lines and not rendered_lines[-1]:
        rendered_lines.pop()
    rendered = "\n".join(rendered_lines) + "\n"
    validate_rendered(output_name, rendered)
    return rendered


def generated_outputs(root: Path) -> dict[Path, str]:
    outputs: dict[Path, str] = {}
    for source_name, output_name in TEMPLATE_PAIRS:
        output_path = Path("cfg") / output_name
        outputs[output_path] = render_template(root, source_name, output_name)
    if outputs[Path("cfg/Custom_Stash_Mainland.ini")] != outputs[
        Path("cfg/Custom_Stash.ini")
    ]:
        raise ValueError("Stash Mainland compatibility output diverged from standard")
    return outputs


def check_outputs(root: Path, outputs: dict[Path, str] | None = None) -> tuple[Path, ...]:
    expected = outputs if outputs is not None else generated_outputs(root)
    mismatches = []
    for relative_path, content in expected.items():
        path = root / relative_path
        if not path.exists() or path.read_text(encoding="utf-8") != content:
            mismatches.append(relative_path)
    return tuple(mismatches)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="check committed outputs")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    outputs = generated_outputs(root)
    if args.check:
        mismatches = check_outputs(root, outputs)
        if mismatches:
            for path in mismatches:
                print(f"outdated generated Stash template: {path.as_posix()}")
            return 1
        print("generated Stash templates are current")
        return 0

    for relative_path, content in outputs.items():
        (root / relative_path).write_text(content, encoding="utf-8")
        print(f"generated {relative_path.as_posix()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
