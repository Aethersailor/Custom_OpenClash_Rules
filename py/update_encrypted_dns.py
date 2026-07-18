#!/usr/bin/env python3
"""Update Encrypted_DNS.list from maintained encrypted-DNS data sources."""

from __future__ import annotations

import argparse
import base64
import binascii
import ipaddress
import os
import tempfile
import time
import urllib.request
from pathlib import Path


DOMAIN_URL = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/doh-onlydomains.txt"
IP_URL = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/ips/doh.txt"
STAMP_URLS = (
    "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md",
    "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/relays.md",
    "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/odoh-servers.md",
    "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/odoh-relays.md",
)

OUTPUT_FILE = Path(__file__).resolve().parent.parent / "rule" / "Encrypted_DNS.list"
USER_AGENT = "Custom_OpenClash_Rules/Encrypted_DNS updater"
MIN_DOMAINS = 3_000
MIN_IP_NETWORKS = 1_400
MIN_IPV6_NETWORKS = 25
DOMAIN_ANCHORS = {"cloudflare-dns.com", "dns.google"}
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


def validate_networks(networks: set[ipaddress.IPv4Network | ipaddress.IPv6Network]) -> None:
    ipv6_count = sum(network.version == 6 for network in networks)
    missing = IP_ANCHORS - networks
    if len(networks) < MIN_IP_NETWORKS or ipv6_count < MIN_IPV6_NETWORKS or missing:
        raise ValueError(
            f"IP source validation failed: count={len(networks)}, IPv6={ipv6_count}, "
            f"missing anchors={sorted(str(network) for network in missing)}"
        )


def render(
    domains: set[str],
    networks: set[ipaddress.IPv4Network | ipaddress.IPv6Network],
) -> str:
    lines = [
        "# NAME: Encrypted_DNS",
        "# AUTHOR: Aethersailor",
        "# REPO: https://github.com/Aethersailor/Custom_OpenClash_Rules",
        "# 加密 DNS 规则",
        "# AUTO-GENERATED: py/update_encrypted_dns.py",
        f"# SOURCE-DOMAINS: {DOMAIN_URL}",
        f"# SOURCE-IPS: {IP_URL}",
        *(f"# SOURCE-STAMPS: {url}" for url in STAMP_URLS),
        "",
        *(f"DOMAIN-SUFFIX,{domain}" for domain in sorted(domains)),
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

    domains: set[str] = set()
    networks: set[ipaddress.IPv4Network | ipaddress.IPv6Network] = set()
    for rule in rules:
        parts = rule.split(",")
        if len(parts) == 2 and parts[0] == "DOMAIN-SUFFIX":
            domains.add(normalize_domain(parts[1]))
            continue
        if len(parts) == 3 and parts[0] in {"IP-CIDR", "IP-CIDR6"} and parts[2] == "no-resolve":
            network = ipaddress.ip_network(parts[1], strict=False)
            expected = "IP-CIDR6" if network.version == 6 else "IP-CIDR"
            if parts[0] != expected or str(network) != parts[1]:
                raise ValueError(f"non-canonical IP rule: {rule}")
            networks.add(network)
            continue
        raise ValueError(f"unsupported generated rule: {rule}")

    missing_domains = DOMAIN_ANCHORS - domains
    if len(domains) < MIN_DOMAINS or missing_domains:
        raise ValueError(
            f"output domain validation failed: count={len(domains)}, "
            f"missing anchors={sorted(missing_domains)}"
        )
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
    domains = parse_domains(download(DOMAIN_URL))
    networks = parse_ip_source(download(IP_URL))
    stamp_contents = tuple(download(url) for url in STAMP_URLS)
    networks.update(parse_stamp_ips(stamp_contents))
    validate_networks(networks)
    output = render(domains, networks)
    validate_output(output)
    write_atomic(output)
    ipv6_count = sum(network.version == 6 for network in networks)
    print(
        f"Updated {OUTPUT_FILE}: {len(domains)} domains, "
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
