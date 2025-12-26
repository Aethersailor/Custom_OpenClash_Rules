#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
自动生成 Game_Download_CDN.list 规则文件
从 v2fly/domain-list-community 上游文件转换为 Clash .list 格式
"""

import re
import urllib.request
from pathlib import Path

# 配置
UPSTREAM_URL = "https://raw.githubusercontent.com/v2fly/domain-list-community/refs/heads/master/data/category-game-platforms-download"
OUTPUT_FILE = Path(__file__).parent.parent / "rule" / "Game_Download_CDN.list"
HEADER_LINES = 20  # 保留原文件前 20 行注释头


def download_upstream() -> str:
    """下载上游文件内容"""
    print(f"[i] 正在下载上游文件: {UPSTREAM_URL}")
    with urllib.request.urlopen(UPSTREAM_URL) as response:
        content = response.read().decode('utf-8')
    print(f"[✓] 下载完成，共 {len(content.splitlines())} 行")
    return content


def convert_line(line: str) -> str:
    """
    转换单行规则
    full:example.com -> DOMAIN-SUFFIX,example.com
    full:example.com @cn -> DOMAIN-SUFFIX,example.com
    """
    line = line.strip()
    
    # 空行或注释行直接返回
    if not line or line.startswith('#'):
        return line
    
    # 匹配 full: 格式
    match = re.match(r'^full:([^\s@]+)', line)
    if match:
        domain = match.group(1)
        return f"DOMAIN-SUFFIX,{domain}"
    
    # 其他格式（如 regexp: 等）暂不支持，保留原样并添加注释
    if ':' in line:
        return f"# [UNSUPPORTED] {line}"
    
    return line


def generate_rules(upstream_content: str) -> list[str]:
    """转换上游内容为 Clash 规则"""
    rules = []
    for line in upstream_content.splitlines():
        converted = convert_line(line)
        if converted:  # 跳过空字符串
            rules.append(converted)
    return rules


def read_header() -> list[str]:
    """读取原文件的前 N 行注释头"""
    if not OUTPUT_FILE.exists():
        print(f"[!] 警告: {OUTPUT_FILE} 不存在，将使用默认头部")
        return []
    
    with open(OUTPUT_FILE, 'r', encoding='utf-8') as f:
        lines = [f.readline().rstrip('\n\r') for _ in range(HEADER_LINES)]
    
    print(f"[✓] 已读取原文件头部 {len(lines)} 行")
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
    
    print(f"[✓] 已生成文件: {OUTPUT_FILE}")
    print(f"[✓] 规则总数: {len([r for r in rules if r and not r.startswith('#')])} 条")


def main():
    print("=" * 60)
    print("Game_Download_CDN.list 自动生成工具")
    print("=" * 60)
    
    # 1. 下载上游文件
    upstream_content = download_upstream()
    
    # 2. 转换规则
    print("[i] 正在转换规则格式...")
    rules = generate_rules(upstream_content)
    
    # 3. 读取原文件头部
    header = read_header()
    
    # 4. 写入文件
    write_output(header, rules)
    
    print("=" * 60)
    print("[✓] 生成完成！")
    print("=" * 60)


if __name__ == "__main__":
    main()
