#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
自动生成 Game_Download_CDN.list 规则文件
从 v2fly/domain-list-community 上游文件转换为 Clash .list 格式
"""

import argparse
import urllib.request
from collections import Counter
from pathlib import Path

# 配置
UPSTREAM_URL = "https://raw.githubusercontent.com/v2fly/domain-list-community/refs/heads/master/data/category-game-platforms-download"
OUTPUT_FILE = Path(__file__).parent.parent / "rule" / "Game_Download_CDN.list"
ALLOWED_RULE_PREFIXES = ("DOMAIN,", "DOMAIN-SUFFIX,", "DOMAIN-KEYWORD,", "DOMAIN-REGEX,")


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


def generate_rules(upstream_content: str) -> list[str]:
    """转换上游内容为 Clash 规则"""
    rules = []
    seen = set()
    pending_comments = []
    for line in upstream_content.splitlines():
        converted = convert_line(line)
        if converted and converted.startswith('#'):
            pending_comments.append(converted)
        elif converted and converted not in seen:
            rules.extend(pending_comments)
            pending_comments.clear()
            rules.append(converted)
            seen.add(converted)
        elif converted:
            # Drop the comment block belonging only to a duplicate rule.
            pending_comments.clear()
    return rules


def validate_rules(lines: list[str]) -> None:
    """校验转换后的 Clash 规则格式与唯一性。"""
    rules = [line for line in lines if line and not line.startswith(("#", ";"))]
    invalid = [rule for rule in rules if not rule.startswith(ALLOWED_RULE_PREFIXES)]
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
        "# group\nexample.com @cn\nexample.com # duplicate\nfull:www.example.com\n"
    )
    expected = ["# group", "DOMAIN-SUFFIX,example.com", "DOMAIN,www.example.com"]
    if converted != expected:
        raise AssertionError(f"属性清理或去重结果异常：{converted!r}")

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
    rules = generate_rules(upstream_content)
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
