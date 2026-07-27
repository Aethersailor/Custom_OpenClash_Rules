#!/usr/bin/env python3
"""Update Encrypted_DNS.list from maintained encrypted-DNS data sources."""

from __future__ import annotations

import argparse
import base64
import binascii
import ipaddress
import json
import os
import re
import tempfile
import time
import urllib.request
from pathlib import Path


DOMAIN_URL = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/doh-onlydomains.txt"
IP_URL = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/ips/doh.txt"
# The official compiled plain output already resolves recursive include rules,
# attribute filters, and affiliations using domain-list-community's own builder.
GEOSITE_URL = (
    "https://github.com/v2fly/domain-list-community/releases/latest/download/"
    "dlc.dat_plain.yml"
)
STAMP_URLS = (
    "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md",
    "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/relays.md",
    "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/odoh-servers.md",
    "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/odoh-relays.md",
)

OUTPUT_FILE = Path(__file__).resolve().parent.parent / "rule" / "Encrypted_DNS.list"
USER_AGENT = "Custom_OpenClash_Rules/Encrypted_DNS updater"
MIN_DOMAINS = 3_000
MIN_GEOSITE_RULES = 100
MIN_IP_NETWORKS = 1_400
MIN_IPV6_NETWORKS = 25
DOMAIN_ANCHORS = {"cloudflare-dns.com", "dns.google"}
GEOSITE_ANCHORS = {
    "DOMAIN-SUFFIX,cloudflare-dns.com",
    "DOMAIN-SUFFIX,nextdns.io",
    "DOMAIN,dns.google",
}
IP_ANCHORS = {
    ipaddress.ip_network("1.0.0.1/32"),
    ipaddress.ip_network("1.1.1.1/32"),
}


def download(url: str) -> str:
    """Download a UTF-8 text source with bounded retries."""
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    last_error: Exception | None = None
    for attempt in range(1, 4):
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                return response.read().decode("utf-8-sig")
        except Exception as exc:  # urllib exposes several unrelated error types
            last_error = exc
            if attempt < 3:
                time.sleep(attempt * 2)
    raise RuntimeError(f"failed to download {url}: {last_error}") from last_error


def normalize_domain(value: str) -> str:
    domain = value.strip().rstrip(".").lower()
    if not domain or any(character.isspace() for character in domain):
        raise ValueError(f"invalid domain: {value!r}")
    try:
        ascii_domain = domain.encode("idna").decode("ascii")
    except UnicodeError as exc:
        raise ValueError(f"invalid IDN domain: {value!r}") from exc
    labels = ascii_domain.split(".")
    if len(labels) < 2 or any(
        not label
        or len(label) > 63
        or label.startswith("-")
        or label.endswith("-")
        or not all(character.isalnum() or character == "-" for character in label)
        for label in labels
    ):
        raise ValueError(f"invalid domain: {value!r}")
    return ascii_domain


def parse_domains(content: str) -> set[str]:
    domains = {
        normalize_domain(line)
        for raw_line in content.splitlines()
        if (line := raw_line.strip()) and not line.startswith(("#", ";"))
    }
    missing = DOMAIN_ANCHORS - domains
    if len(domains) < MIN_DOMAINS or missing:
        raise ValueError(
            f"domain source validation failed: count={len(domains)}, "
            f"missing anchors={sorted(missing)}"
        )
    return domains


def strip_geosite_attributes(rule: str) -> str:
    """Remove attributes serialized by dlc.dat_plain.yml from a compiled rule."""
    return re.sub(r"(?::@[A-Za-z0-9_!-]+)+$", "", rule)


def convert_geosite_rule(rule: str) -> str:
    """Convert one compiled domain-list-community rule to Clash syntax."""
    value = strip_geosite_attributes(rule.strip())
    prefix, separator, payload = value.partition(":")
    if not separator:
        raise ValueError(f"GeoSite rule has no type prefix: {rule!r}")

    rule_types = {
        "domain": "DOMAIN-SUFFIX",
        "full": "DOMAIN",
        "keyword": "DOMAIN-KEYWORD",
        "regexp": "DOMAIN-REGEX",
    }
    try:
        rule_type = rule_types[prefix]
    except KeyError as exc:
        raise ValueError(f"unsupported GeoSite rule type: {prefix!r}") from exc

    if rule_type in {"DOMAIN", "DOMAIN-SUFFIX"}:
        payload = normalize_domain(payload)
    else:
        payload = payload.strip()
        if not payload or "\n" in payload or "\r" in payload:
            raise ValueError(f"invalid {prefix} GeoSite rule: {rule!r}")
    return f"{rule_type},{payload}"


def parse_geosite_plain(content: str, list_name: str = "category-doh") -> set[str]:
    """Extract a fully compiled GeoSite list from dlc.dat_plain.yml."""
    in_target = False
    found_target = False
    declared_length: int | None = None
    rules: list[str] = []

    for raw_line in content.splitlines():
        stripped = raw_line.strip()
        if stripped.startswith("- name: "):
            if in_target:
                break
            try:
                current_name = json.loads(stripped.removeprefix("- name: "))
            except json.JSONDecodeError as exc:
                raise ValueError(f"invalid GeoSite list name line: {raw_line!r}") from exc
            if not isinstance(current_name, str):
                raise ValueError(f"GeoSite list name is not text: {current_name!r}")
            in_target = current_name.casefold() == list_name.casefold()
            found_target = found_target or in_target
            continue
        if not in_target:
            continue
        if stripped.startswith("length: "):
            try:
                declared_length = int(stripped.removeprefix("length: "))
            except ValueError as exc:
                raise ValueError(f"invalid GeoSite length line: {raw_line!r}") from exc
        elif stripped.startswith("- "):
            try:
                compiled_rule = json.loads(stripped.removeprefix("- "))
            except json.JSONDecodeError as exc:
                raise ValueError(f"invalid GeoSite rule line: {raw_line!r}") from exc
            if not isinstance(compiled_rule, str):
                raise ValueError(f"GeoSite rule is not text: {compiled_rule!r}")
            rules.append(convert_geosite_rule(compiled_rule))

    if not found_target:
        raise ValueError(f"GeoSite list not found: {list_name}")
    if declared_length is None or declared_length != len(rules):
        raise ValueError(
            f"GeoSite length mismatch for {list_name}: "
            f"declared={declared_length}, parsed={len(rules)}"
        )

    unique_rules = set(rules)
    missing = GEOSITE_ANCHORS - unique_rules
    if len(unique_rules) < MIN_GEOSITE_RULES or missing:
        raise ValueError(
            f"GeoSite source validation failed: count={len(unique_rules)}, "
            f"missing anchors={sorted(missing)}"
        )
    return unique_rules


def suffix_covers(domain: str, suffix: str) -> bool:
    return domain == suffix or domain.endswith(f".{suffix}")


def deduplicate_domain_rules(rules: set[str]) -> set[str]:
    """Remove exact and suffix-covered rules without changing match semantics."""
    by_type: dict[str, set[str]] = {
        "DOMAIN": set(),
        "DOMAIN-SUFFIX": set(),
        "DOMAIN-KEYWORD": set(),
        "DOMAIN-REGEX": set(),
    }
    for rule in rules:
        rule_type, separator, payload = rule.partition(",")
        if not separator or rule_type not in by_type:
            raise ValueError(f"unsupported domain rule: {rule}")
        if rule_type in {"DOMAIN", "DOMAIN-SUFFIX"}:
            payload = normalize_domain(payload)
        elif not payload:
            raise ValueError(f"empty domain rule: {rule}")
        by_type[rule_type].add(payload)

    kept_suffixes: list[str] = []
    for suffix in sorted(by_type["DOMAIN-SUFFIX"], key=lambda item: (item.count("."), item)):
        if not any(suffix_covers(suffix, parent) for parent in kept_suffixes):
            kept_suffixes.append(suffix)

    exact_domains = {
        domain
        for domain in by_type["DOMAIN"]
        if not any(suffix_covers(domain, suffix) for suffix in kept_suffixes)
    }
    return {
        *(f"DOMAIN,{domain}" for domain in exact_domains),
        *(f"DOMAIN-SUFFIX,{suffix}" for suffix in kept_suffixes),
        *(f"DOMAIN-KEYWORD,{keyword}" for keyword in by_type["DOMAIN-KEYWORD"]),
        *(f"DOMAIN-REGEX,{regexp}" for regexp in by_type["DOMAIN-REGEX"]),
    }


def rule_is_covered(rule: str, merged_rules: set[str]) -> bool:
    if rule in merged_rules:
        return True
    rule_type, payload = rule.split(",", 1)
    if rule_type not in {"DOMAIN", "DOMAIN-SUFFIX"}:
        return False
    suffixes = (
        candidate.split(",", 1)[1]
        for candidate in merged_rules
        if candidate.startswith("DOMAIN-SUFFIX,")
    )
    return any(suffix_covers(payload, suffix) for suffix in suffixes)


def merge_domain_rules(hagezi_domains: set[str], geosite_rules: set[str]) -> set[str]:
    combined = {*(f"DOMAIN-SUFFIX,{domain}" for domain in hagezi_domains), *geosite_rules}
    merged = deduplicate_domain_rules(combined)
    missing = sorted(rule for rule in geosite_rules if not rule_is_covered(rule, merged))
    if missing:
        raise ValueError(f"merged output lost GeoSite coverage: {missing}")
    return merged


def parse_ip_source(content: str) -> set[ipaddress.IPv4Network | ipaddress.IPv6Network]:
    networks: set[ipaddress.IPv4Network | ipaddress.IPv6Network] = set()
    for raw_line in content.splitlines():
        value = raw_line.split("#", 1)[0].strip()
        if not value:
            continue
        try:
            network = ipaddress.ip_network(value, strict=False)
        except ValueError as exc:
            raise ValueError(f"invalid IP entry in HaGeZi source: {value!r}") from exc
        if network.network_address.is_global:
            networks.add(network)
    return networks


def decode_stamp_address(stamp: str) -> str | None:
    encoded = stamp.removeprefix("sdns://").strip()
    try:
        payload = base64.urlsafe_b64decode(encoded + "=" * (-len(encoded) % 4))
    except (ValueError, binascii.Error):
        return None
    if not payload:
        return None

    # DNS stamps put the server-address length after the protocol byte for
    # relay stamps and after the protocol byte plus eight property bytes for
    # resolver stamps.
    offset = 1 if payload[0] & 0x80 else 9
    if len(payload) <= offset:
        return None
    length = payload[offset]
    start = offset + 1
    end = start + length
    if length == 0 or end > len(payload):
        return None
    try:
        return payload[start:end].decode("utf-8")
    except UnicodeDecodeError:
        return None


def address_host(server_address: str) -> str:
    if server_address.startswith("[") and "]" in server_address:
        return server_address[1:].split("]", 1)[0]
    if server_address.count(":") == 1:
        return server_address.rsplit(":", 1)[0]
    return server_address


def parse_stamp_ips(contents: tuple[str, ...]) -> set[ipaddress.IPv4Network | ipaddress.IPv6Network]:
    networks: set[ipaddress.IPv4Network | ipaddress.IPv6Network] = set()
    for content in contents:
        for raw_line in content.splitlines():
            line = raw_line.strip()
            if not line.startswith("sdns://"):
                continue
            server_address = decode_stamp_address(line)
            if not server_address:
                continue
            try:
                address = ipaddress.ip_address(address_host(server_address))
            except ValueError:
                # Some stamps intentionally contain hostnames. HaGeZi supplies
                # the domain rules, so only literal endpoint IPs belong here.
                continue
            if address.is_global:
                networks.add(ipaddress.ip_network(address.exploded))
    return networks


def network_sort_key(
    network: ipaddress.IPv4Network | ipaddress.IPv6Network,
) -> tuple[int, int, int]:
    return network.version, int(network.network_address), network.prefixlen


def deduplicate_networks(
    networks: set[ipaddress.IPv4Network | ipaddress.IPv6Network],
) -> set[ipaddress.IPv4Network | ipaddress.IPv6Network]:
    """Remove networks already covered by a broader source network."""
    kept: list[ipaddress.IPv4Network | ipaddress.IPv6Network] = []
    for network in sorted(
        networks,
        key=lambda item: (item.version, item.prefixlen, int(item.network_address)),
    ):
        if not any(
            network.version == parent.version and network.subnet_of(parent)
            for parent in kept
        ):
            kept.append(network)
    return set(kept)


def validate_networks(networks: set[ipaddress.IPv4Network | ipaddress.IPv6Network]) -> None:
    ipv6_count = sum(network.version == 6 for network in networks)
    missing = {
        anchor
        for anchor in IP_ANCHORS
        if not any(
            anchor.version == network.version and anchor.subnet_of(network)
            for network in networks
        )
    }
    if len(networks) < MIN_IP_NETWORKS or ipv6_count < MIN_IPV6_NETWORKS or missing:
        raise ValueError(
            f"IP source validation failed: count={len(networks)}, IPv6={ipv6_count}, "
            f"missing anchors={sorted(str(network) for network in missing)}"
        )


def render(
    domain_rules: set[str],
    networks: set[ipaddress.IPv4Network | ipaddress.IPv6Network],
) -> str:
    lines = [
        "# NAME: Encrypted_DNS",
        "# AUTHOR: Aethersailor",
        "# REPO: https://github.com/Aethersailor/Custom_OpenClash_Rules",
        "# 加密 DNS 规则",
        "# AUTO-GENERATED: py/update_encrypted_dns.py",
        f"# SOURCE-DOMAINS: {DOMAIN_URL}",
        f"# SOURCE-GEOSITE: {GEOSITE_URL}#category-doh",
        f"# SOURCE-IPS: {IP_URL}",
        *(f"# SOURCE-STAMPS: {url}" for url in STAMP_URLS),
        "",
        *sorted(domain_rules),
        "",
    ]
    for network in sorted(networks, key=network_sort_key):
        rule_type = "IP-CIDR6" if network.version == 6 else "IP-CIDR"
        lines.append(f"{rule_type},{network},no-resolve")
    return "\n".join(lines) + "\n"


def validate_output(content: str) -> None:
    rules = [
        line.strip()
        for line in content.splitlines()
        if line.strip() and not line.lstrip().startswith(("#", ";"))
    ]
    if len(rules) != len(set(rules)):
        raise ValueError("generated output contains duplicate rules")

    domain_rules: set[str] = set()
    networks: set[ipaddress.IPv4Network | ipaddress.IPv6Network] = set()
    for rule in rules:
        rule_type, separator, payload = rule.partition(",")
        if separator and rule_type in {"DOMAIN", "DOMAIN-SUFFIX"}:
            domain_rules.add(f"{rule_type},{normalize_domain(payload)}")
            continue
        if separator and rule_type in {"DOMAIN-KEYWORD", "DOMAIN-REGEX"} and payload:
            domain_rules.add(rule)
            continue
        parts = rule.split(",")
        if len(parts) == 3 and parts[0] in {"IP-CIDR", "IP-CIDR6"} and parts[2] == "no-resolve":
            network = ipaddress.ip_network(parts[1], strict=False)
            expected = "IP-CIDR6" if network.version == 6 else "IP-CIDR"
            if parts[0] != expected or str(network) != parts[1]:
                raise ValueError(f"non-canonical IP rule: {rule}")
            networks.add(network)
            continue
        raise ValueError(f"unsupported generated rule: {rule}")

    if domain_rules != deduplicate_domain_rules(domain_rules):
        raise ValueError("generated output contains semantically redundant domain rules")
    output_anchors = {f"DOMAIN-SUFFIX,{domain}" for domain in DOMAIN_ANCHORS}
    missing_domains = sorted(
        rule for rule in output_anchors if not rule_is_covered(rule, domain_rules)
    )
    if len(domain_rules) < MIN_DOMAINS or missing_domains:
        raise ValueError(
            f"output domain validation failed: count={len(domain_rules)}, "
            f"missing anchors={sorted(missing_domains)}"
        )
    missing_geosite = sorted(
        rule for rule in GEOSITE_ANCHORS if not rule_is_covered(rule, domain_rules)
    )
    if missing_geosite:
        raise ValueError(f"output is missing GeoSite anchors: {missing_geosite}")
    if networks != deduplicate_networks(networks):
        raise ValueError("generated output contains semantically redundant IP networks")
    validate_networks(networks)


def write_atomic(content: str) -> None:
    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    file_descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{OUTPUT_FILE.name}.", dir=OUTPUT_FILE.parent
    )
    temporary = Path(temporary_name)
    try:
        with os.fdopen(file_descriptor, "w", encoding="utf-8", newline="\n") as stream:
            stream.write(content)
        os.replace(temporary, OUTPUT_FILE)
    finally:
        temporary.unlink(missing_ok=True)


def update() -> None:
    hagezi_domains = parse_domains(download(DOMAIN_URL))
    geosite_rules = parse_geosite_plain(download(GEOSITE_URL))
    domain_rules = merge_domain_rules(hagezi_domains, geosite_rules)
    networks = parse_ip_source(download(IP_URL))
    stamp_contents = tuple(download(url) for url in STAMP_URLS)
    networks.update(parse_stamp_ips(stamp_contents))
    networks = deduplicate_networks(networks)
    validate_networks(networks)
    output = render(domain_rules, networks)
    validate_output(output)
    write_atomic(output)
    ipv6_count = sum(network.version == 6 for network in networks)
    print(
        f"Updated {OUTPUT_FILE}: {len(domain_rules)} domain rules, "
        f"{len(networks)} IP networks ({ipv6_count} IPv6)."
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="validate the existing output without downloading")
    args = parser.parse_args()

    if args.check:
        validate_output(OUTPUT_FILE.read_text(encoding="utf-8-sig"))
        print(f"Validated {OUTPUT_FILE}.")
    else:
        update()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
