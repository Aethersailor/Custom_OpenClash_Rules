#!/usr/bin/env python3
"""Extract public game destinations written to the UU virtual adapter."""

from __future__ import annotations

import argparse
import hashlib
import ipaddress
import json
import shutil
import subprocess
from collections import Counter
from datetime import datetime
from pathlib import Path


REPOSITORY = "Aethersailor/Custom_OpenClash_Rules"


def read_uu_routes(interface_name: str) -> list[dict[str, object]]:
    powershell = shutil.which("pwsh") or shutil.which("powershell")
    if not powershell:
        raise RuntimeError("PowerShell is required to read the Windows route table")

    escaped_name = interface_name.replace("'", "''")
    command = (
        f"$adapter = Get-NetAdapter -IncludeHidden -Name '{escaped_name}' "
        "-ErrorAction Stop; "
        "$routes = @(Get-NetRoute -AddressFamily IPv4 "
        "-InterfaceIndex $adapter.ifIndex -ErrorAction Stop | "
        "Select-Object DestinationPrefix, NextHop, InterfaceIndex); "
        "$routes | ConvertTo-Json -Depth 3 -Compress"
    )
    completed = subprocess.run(
        [powershell, "-NoProfile", "-NonInteractive", "-Command", command],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8-sig",
    )
    if completed.returncode != 0:
        raise RuntimeError(completed.stderr.strip() or "Unable to read UU routes")

    payload = json.loads(completed.stdout or "[]")
    if isinstance(payload, dict):
        return [payload]
    if not isinstance(payload, list):
        raise RuntimeError("Unexpected route-table response")
    return payload


def normalize_routes(
    rows: list[dict[str, object]], minimum_routes: int = 100
) -> tuple[tuple[ipaddress.IPv4Network, ...], str, int]:
    gateway_counts = Counter(
        str(row.get("NextHop", ""))
        for row in rows
        if str(row.get("NextHop", "")) not in {"", "0.0.0.0"}
    )
    if not gateway_counts:
        raise RuntimeError("UU adapter has no routed gateway")
    gateway, gateway_route_count = gateway_counts.most_common(1)[0]
    if gateway_route_count < minimum_routes:
        raise RuntimeError(
            f"UU route snapshot is unexpectedly small: {gateway_route_count} routes"
        )

    candidates: set[ipaddress.IPv4Network] = set()
    for row in rows:
        if str(row.get("NextHop", "")) != gateway:
            continue
        prefix = str(row.get("DestinationPrefix", ""))
        try:
            network = ipaddress.ip_network(prefix, strict=False)
        except ValueError as exc:
            raise RuntimeError(f"Invalid route prefix returned by Windows: {prefix}") from exc
        if not isinstance(network, ipaddress.IPv4Network):
            continue
        if not (
            network.network_address.is_global and network.broadcast_address.is_global
        ):
            continue
        candidates.add(network)

    kept: list[ipaddress.IPv4Network] = []
    for network in sorted(
        candidates, key=lambda item: (item.prefixlen, int(item.network_address))
    ):
        if any(network.subnet_of(existing) for existing in kept):
            continue
        kept.append(network)

    normalized = tuple(
        sorted(kept, key=lambda item: (int(item.network_address), item.prefixlen))
    )
    if len(normalized) < minimum_routes:
        raise RuntimeError(
            f"UU snapshot has only {len(normalized)} usable public routes after filtering"
        )
    return normalized, gateway, gateway_route_count


def render_list(
    networks: tuple[ipaddress.IPv4Network, ...], region_en: str, region_zh: str
) -> str:
    updated_at = datetime.now().astimezone().strftime("%Y/%m/%d")
    lines = [
        f"# Battlefield 6 {region_en} Game Rule",
        "# 《战地风云 6》游戏规则",
        "# 类型：IPCIDR",
        "# 作者: Aethersailor",
        f"# 仓库: https://github.com/{REPOSITORY}",
        f"# 更新日期 {updated_at}",
        f"# 区服：{region_zh}",
        "# 提取方式：UU 加速器 Windows PC 版，路由模式",
        "# 内容：UU 在该区服加速时写入虚拟网卡的目标 IPv4 路由",
        "# 已过滤本地、专用、保留和被上级网段覆盖的地址，并附加 no-resolve 参数",
        "",
    ]
    lines.extend(f"IP-CIDR,{network},no-resolve" for network in networks)
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--region-en", required=True)
    parser.add_argument("--region-zh", required=True)
    parser.add_argument("--interface", default="UU")
    parser.add_argument("--minimum-routes", type=int, default=100)
    args = parser.parse_args()

    rows = read_uu_routes(args.interface)
    networks, gateway, routed_count = normalize_routes(rows, args.minimum_routes)
    content = render_list(networks, args.region_en, args.region_zh)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(content, encoding="utf-8", newline="\n")
    digest = hashlib.sha256(content.encode()).hexdigest()
    print(
        f"Wrote {args.output}: raw={len(rows)}, routed={routed_count}, "
        f"usable={len(networks)}, gateway={gateway}, sha256={digest}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
