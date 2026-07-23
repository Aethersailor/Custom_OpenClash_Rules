#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
自动生成 Game_Download_CDN.list 规则文件
从 v2fly/domain-list-community 上游文件转换为 Clash .list 格式
"""

import argparse
import ipaddress
import urllib.request
from collections import Counter
from pathlib import Path

# 配置
UPSTREAM_URL = "https://raw.githubusercontent.com/v2fly/domain-list-community/refs/heads/master/data/category-game-platforms-download"
REPOSITORY_ROOT = Path(__file__).resolve().parent.parent
STEAM_CDN_FILE = REPOSITORY_ROOT / "rule" / "Steam_CDN.list"
OUTPUT_FILE = REPOSITORY_ROOT / "rule" / "Game_Download_CDN.list"
STEAM_SOURCE_COMMENT = "# 以下规则补充自本项目 rule/Steam_CDN.list"
ALLOWED_RULE_TYPES = {
    "DOMAIN",
    "DOMAIN-SUFFIX",
    "DOMAIN-KEYWORD",
    "DOMAIN-REGEX",
    "IP-CIDR",
    "IP-CIDR6",
}


def download_upstream() -> str:
    """下载上游文件内容"""
    print(f"[i] 正在下载上游文件: {UPSTREAM_URL}")
    request = urllib.request.Request(UPSTREAM_URL, headers={"User-Agent": "Custom_OpenClash_Rules"})
    with urllib.request.urlopen(request, timeout=60) as response:
        content = response.read().decode('utf-8')
    print(f"[OK] 下载完成，共 {len(content.splitlines())} 行")
    return content


def convert_line(line: str) -> str | None:
    """
    转换单行规则
    example.com / domain:example.com -> DOMAIN-SUFFIX,example.com
    full:example.com -> DOMAIN,example.com
    keyword:example -> DOMAIN-KEYWORD,example
    regexp:... -> DOMAIN-REGEX,...
    """
    line = line.strip()
    if line.startswith('#'):
        return line
    line = line.split('#', 1)[0].strip()
    
    # 空行或注释行直接返回
    if not line:
        return None

    value = line.split()[0].split('&', 1)[0]
    if value.startswith("include:"):
        raise ValueError(f"上游出现尚未展开的 include 规则：{line}")

    if ':' in value:
        rule_type, value = value.split(':', 1)
    else:
        rule_type = "domain"

    mappings = {
        "domain": "DOMAIN-SUFFIX",
        "full": "DOMAIN",
        "keyword": "DOMAIN-KEYWORD",
        "regexp": "DOMAIN-REGEX",
    }
    if rule_type not in mappings or not value:
        raise ValueError(f"不支持的上游规则格式：{line}")
    return f"{mappings[rule_type]},{value}"


def normalize_clash_rule(line: str) -> str:
    """规范化 Clash 规则，消除大小写、空白、CIDR 写法等表面差异。"""
    parts = [part.strip() for part in line.split(",")]
    rule_type = parts[0].upper()
    if rule_type not in ALLOWED_RULE_TYPES or len(parts) < 2 or not parts[1]:
        raise ValueError(f"不支持的 Clash 规则格式：{line}")

    value = parts[1]
    if rule_type in {"DOMAIN", "DOMAIN-SUFFIX", "DOMAIN-KEYWORD"}:
        value = value.lower().rstrip(".")
    elif rule_type in {"IP-CIDR", "IP-CIDR6"}:
        network = ipaddress.ip_network(value, strict=False)
        expected_type = "IP-CIDR6" if network.version == 6 else "IP-CIDR"
        if rule_type != expected_type:
            raise ValueError(f"{value} 应使用 {expected_type}，而不是 {rule_type}")
        value = str(network)
        return f"{rule_type},{value},no-resolve"

    return f"{rule_type},{value}"


def rule_covers(covering_rule: str, candidate_rule: str) -> bool:
    """判断前一条规则是否已完整覆盖后一条规则。"""
    if covering_rule == candidate_rule:
        return True

    covering_type, covering_value, *_ = covering_rule.split(",")
    candidate_type, candidate_value, *_ = candidate_rule.split(",")

    if covering_type == "DOMAIN-SUFFIX":
        if candidate_type == "DOMAIN":
            return candidate_value == covering_value or candidate_value.endswith(f".{covering_value}")
        if candidate_type == "DOMAIN-SUFFIX":
            return candidate_value == covering_value or candidate_value.endswith(f".{covering_value}")

    if covering_type in {"IP-CIDR", "IP-CIDR6"} and candidate_type == covering_type:
        covering_network = ipaddress.ip_network(covering_value)
        candidate_network = ipaddress.ip_network(candidate_value)
        return candidate_network.subnet_of(covering_network)

    return False


def deduplicate_rules(*sources: list[str]) -> list[str]:
    """合并多组规则并按精确值、域名覆盖和 CIDR 覆盖关系去重。"""
    accepted: list[tuple[list[str], str]] = []
    for source in sources:
        pending_comments: list[str] = []
        for line in source:
            stripped = line.strip()
            if not stripped:
                continue
            if stripped.startswith(("#", ";")):
                pending_comments.append(stripped)
                continue

            candidate = normalize_clash_rule(stripped)
            if any(rule_covers(existing, candidate) for _, existing in accepted):
                pending_comments.clear()
                continue

            accepted = [
                (comments, existing)
                for comments, existing in accepted
                if not rule_covers(candidate, existing)
            ]
            accepted.append((pending_comments, candidate))
            pending_comments = []

    result: list[str] = []
    for comments, rule in accepted:
        result.extend(comments)
        result.append(rule)
    return result


def generate_rules(upstream_content: str, steam_content: str = "") -> list[str]:
    """转换 v2fly 上游并合并本项目 Steam CDN 补充规则。"""
    upstream_lines: list[str] = []
    for line in upstream_content.splitlines():
        converted = convert_line(line)
        if converted:
            upstream_lines.append(converted)

    steam_lines = [
        line
        for line in steam_content.splitlines()
        if line.strip() and not line.lstrip().startswith(("#", ";"))
    ]
    upstream_rules = deduplicate_rules(upstream_lines)
    merged_rules = deduplicate_rules(upstream_rules, steam_lines)
    upstream_values = {
        normalize_clash_rule(line)
        for line in upstream_rules
        if line and not line.startswith(("#", ";"))
    }
    steam_values = {normalize_clash_rule(line) for line in steam_lines}

    result: list[str] = []
    source_comment_added = False
    for line in merged_rules:
        if not line.startswith(("#", ";")):
            normalized = normalize_clash_rule(line)
            if (
                not source_comment_added
                and normalized in steam_values
                and normalized not in upstream_values
            ):
                result.append(STEAM_SOURCE_COMMENT)
                source_comment_added = True
        result.append(line)
    return result


def validate_rules(lines: list[str]) -> None:
    """校验转换后的 Clash 规则格式与唯一性。"""
    rules = [line for line in lines if line and not line.startswith(("#", ";"))]
    invalid = [rule for rule in rules if rule.split(",", 1)[0] not in ALLOWED_RULE_TYPES]
    duplicates = [rule for rule, count in Counter(rules).items() if count > 1]
    if not rules:
        raise ValueError("没有生成任何游戏 CDN 规则。")
    if invalid:
        raise ValueError(f"包含无效 Clash 规则：{invalid[:5]}")
    if duplicates:
        raise ValueError(f"包含重复规则：{duplicates[:5]}")


def run_self_check() -> None:
    """检查上游格式映射、属性清理与去重逻辑。"""
    cases = {
        "example.com": "DOMAIN-SUFFIX,example.com",
        "domain:example.com @cn": "DOMAIN-SUFFIX,example.com",
        "full:www.example.com": "DOMAIN,www.example.com",
        "keyword:example": "DOMAIN-KEYWORD,example",
        r"regexp:^example\.com$": r"DOMAIN-REGEX,^example\.com$",
    }
    for source, expected in cases.items():
        actual = convert_line(source)
        if actual != expected:
            raise AssertionError(f"{source!r}: expected {expected!r}, got {actual!r}")

    converted = generate_rules(
        "# group\nexample.com @cn\nexample.com # duplicate\nfull:www.example.com\n",
        "DOMAIN,www.example.com\nDOMAIN-SUFFIX,example.com\nIP-CIDR,192.0.2.1/24\n"
    )
    expected = [
        "# group",
        "DOMAIN-SUFFIX,example.com",
        STEAM_SOURCE_COMMENT,
        "IP-CIDR,192.0.2.0/24,no-resolve",
    ]
    if converted != expected:
        raise AssertionError(f"属性清理或去重结果异常：{converted!r}")

    cidr_rules = deduplicate_rules(
        ["IP-CIDR,192.0.2.128/25"],
        ["IP-CIDR,192.0.2.0/24,no-resolve"],
    )
    if cidr_rules != ["IP-CIDR,192.0.2.0/24,no-resolve"]:
        raise AssertionError(f"CIDR 覆盖去重结果异常：{cidr_rules!r}")

    try:
        convert_line("include:another-list")
    except ValueError:
        pass
    else:
        raise AssertionError("未展开的 include 规则应当失败。")


def read_header() -> list[str]:
    """读取原文件的前 N 行注释头"""
    if not OUTPUT_FILE.exists():
        print(f"[!] 警告: {OUTPUT_FILE} 不存在，将使用默认头部")
        return []
    
    lines = []
    header_end = "# 建议使用 geosite:category-game-platforms-download"
    found_header_end = False
    with open(OUTPUT_FILE, 'r', encoding='utf-8') as f:
        for line in f:
            stripped = line.rstrip('\n\r')
            lines.append(stripped)
            if stripped == header_end:
                found_header_end = True
                break
    if not found_header_end:
        raise ValueError(f"未找到规则头结束标记：{header_end}")
    
    while lines and not lines[-1]:
        lines.pop()
    lines.append("")
    print(f"[OK] 已读取原文件头部 {len(lines)} 行")
    return lines


def write_output(header: list[str], rules: list[str]):
    """写入最终文件"""
    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    
    with open(OUTPUT_FILE, 'w', encoding='utf-8', newline='\n') as f:
        # 写入头部
        for line in header:
            f.write(line + '\n')
        
        # 写入规则
        for rule in rules:
            f.write(rule + '\n')
    
    print(f"[OK] 已生成文件: {OUTPUT_FILE}")
    print(f"[OK] 规则总数: {len([r for r in rules if r and not r.startswith('#')])} 条")


def validate_output_file() -> None:
    lines = OUTPUT_FILE.read_text(encoding="utf-8-sig").splitlines()
    validate_rules(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="仅校验转换逻辑和已生成文件")
    args = parser.parse_args()

    print("=" * 60)
    print("Game_Download_CDN.list 自动生成工具")
    print("=" * 60)

    run_self_check()
    if args.check:
        validate_output_file()
        print("[OK] 转换逻辑和已生成文件校验通过。")
        return 0
    
    # 1. 下载上游文件
    upstream_content = download_upstream()
    
    # 2. 转换规则
    print("[i] 正在转换规则格式...")
    steam_content = STEAM_CDN_FILE.read_text(encoding="utf-8-sig")
    rules = generate_rules(upstream_content, steam_content)
    validate_rules(rules)
    
    # 3. 读取原文件头部
    header = read_header()
    
    # 4. 写入文件
    write_output(header, rules)
    validate_output_file()
    
    print("=" * 60)
    print("[OK] 生成完成！")
    print("=" * 60)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
