#!/usr/bin/env python3
"""Update exact public IP rules for Tailscale's standard STUN service."""

from __future__ import annotations

import argparse
import ipaddress
import json
import os
import tempfile
import time
import urllib.request
from pathlib import Path


DERP_MAP_URL = "https://controlplane.tailscale.com/derpmap/default"
OUTPUT_FILE = Path(__file__).resolve().parent.parent / "rule" / "Tailscale_STUN.list"
USER_AGENT = "Custom_OpenClash_Rules/Tailscale STUN updater"
IPAddress = ipaddress.IPv4Address | ipaddress.IPv6Address


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="validate the existing output without downloading")
    args = parser.parse_args()

    if args.check:
        validate_output(OUTPUT_FILE.read_text(encoding="utf-8-sig"))
        print(f"Validated {OUTPUT_FILE}.")
        return 0

    addresses = parse_derp_map(download())
    content = render(addresses)
    if OUTPUT_FILE.exists() and OUTPUT_FILE.read_text(encoding="utf-8") == content:
        print(f"{OUTPUT_FILE} is already up to date.")
        return 0
    write_atomic(content)
    ipv4_count = sum(address.version == 4 for address in addresses)
    print(f"Updated {OUTPUT_FILE}: {ipv4_count} IPv4 and {len(addresses) - ipv4_count} IPv6 addresses.")
    return 0


def download() -> str:
    request = urllib.request.Request(DERP_MAP_URL, headers={"User-Agent": USER_AGENT})
    last_error: Exception | None = None
    for attempt in range(1, 4):
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                return response.read().decode("utf-8-sig")
        except Exception as exc:
            last_error = exc
            if attempt < 3:
                time.sleep(attempt * 2)
    raise RuntimeError(f"failed to download {DERP_MAP_URL}: {last_error}") from last_error


def parse_derp_map(content: str) -> tuple[IPAddress, ...]:
    data = json.loads(content)
    if not isinstance(data, dict) or not isinstance(data.get("Regions"), dict) or not data["Regions"]:
        raise ValueError("DERP map must contain a non-empty Regions object")

    addresses: set[IPAddress] = set()
    for region in data["Regions"].values():
        if not isinstance(region, dict) or not isinstance(region.get("Nodes"), list):
            raise ValueError("DERP region must contain a Nodes array")
        for node in region["Nodes"]:
            if not isinstance(node, dict):
                raise ValueError("DERP node must be an object")
            port = node.get("STUNPort", 0)
            if type(port) is not int or not -1 <= port <= 65535:
                raise ValueError(f"invalid STUN port: {port!r}")
            # Zero means 3478; -1 disables STUN. Other ports are outside this list's scope.
            if port not in (0, 3478):
                continue
            for version in (4, 6):
                value = node.get(f"IPv{version}", "")
                if value in ("", "none"):
                    continue
                if not isinstance(value, str):
                    raise ValueError(f"invalid IPv{version} address: {value!r}")
                address = ipaddress.ip_address(value)
                if address.version != version or not address.is_global or address.is_multicast:
                    raise ValueError(f"expected public IPv{version} address: {value!r}")
                addresses.add(address)

    if not addresses:
        raise ValueError("DERP map contains no public addresses for standard STUN")
    return tuple(sorted(addresses, key=lambda address: (address.version, int(address))))


def render(addresses: tuple[IPAddress, ...]) -> str:
    lines = [
        "# NAME: Tailscale_STUN",
        "# REPO: https://github.com/Aethersailor/Custom_OpenClash_Rules",
        "# AUTO-GENERATED: py/update_tailscale_stun.py",
        f"# SOURCE: {DERP_MAP_URL}",
        "# SCOPE: Public default-map STUN nodes on UDP 3478; combine with protocol and port rules.",
        "",
    ]
    for address in addresses:
        rule_type = "IP-CIDR6" if address.version == 6 else "IP-CIDR"
        lines.append(f"{rule_type},{address}/{address.max_prefixlen},no-resolve")
    return "\n".join(lines) + "\n"


def validate_output(content: str) -> None:
    addresses: list[IPAddress] = []
    for raw_line in content.splitlines():
        rule = raw_line.strip()
        if not rule or rule.startswith(("#", ";")):
            continue
        parts = rule.split(",")
        if len(parts) != 3 or parts[0] not in {"IP-CIDR", "IP-CIDR6"} or parts[2] != "no-resolve":
            raise ValueError(f"unsupported generated rule: {rule}")
        network = ipaddress.ip_network(parts[1], strict=True)
        address = network.network_address
        expected_type = "IP-CIDR6" if address.version == 6 else "IP-CIDR"
        if (
            parts[0] != expected_type
            or network.prefixlen != address.max_prefixlen
            or parts[1] != str(network)
            or not address.is_global
            or address.is_multicast
        ):
            raise ValueError(f"expected canonical public host rule: {rule}")
        addresses.append(address)
    if not addresses or addresses != sorted(set(addresses), key=lambda address: (address.version, int(address))):
        raise ValueError("generated addresses must be non-empty, unique and sorted")


def write_atomic(content: str) -> None:
    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    file_descriptor, temporary_name = tempfile.mkstemp(prefix=f".{OUTPUT_FILE.name}.", dir=OUTPUT_FILE.parent)
    temporary = Path(temporary_name)
    try:
        with os.fdopen(file_descriptor, "w", encoding="utf-8", newline="\n") as stream:
            stream.write(content)
        os.replace(temporary, OUTPUT_FILE)
    finally:
        temporary.unlink(missing_ok=True)


if __name__ == "__main__":
    raise SystemExit(main())
