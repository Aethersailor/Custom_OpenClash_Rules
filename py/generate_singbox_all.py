#!/usr/bin/env python3
"""
Generate sing-box ALL ruleset + policy group template.
整合 5 个规则仓库的 sing-box 规则集 + 完整策略组，生成 Custom_All sing-box 模板。

来源:
1. Aethersailor/Custom_OpenClash_Rules  - 自定义直连/代理/Steam (本仓库 .list 转 .srs)
2. senshinya/singbox_ruleset           - blackmatrix7 全集精选 (流媒体/游戏/AI/大厂)
3. REIJI007/AdBlock_Rule_For_Sing-box  - 广告拦截 (每20分钟更新)
4. cmontage/proxyrules-cm              - GFW/AI/Google/Netflix (clash yaml 转 srs)
5. Dreista/sing-box-rule-set-cn        - 中国大陆规则

输出:
- singbox/Custom_All.json              - sing-box 完整模板 (策略组 + 规则)
- singbox/ruleset/*.srs                - 下载/编译的规则集
"""
import json
import os
import subprocess
import sys
import tempfile
import urllib.request

# ============ 配置 ============
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "singbox")
RULESET_DIR = os.path.join(OUT_DIR, "ruleset")
os.makedirs(RULESET_DIR, exist_ok=True)

CDN = "https://testingcf.jsdelivr.net/gh"

# 规则集定义: (tag, url, 类型)
# type: remote=直接引用 URL (自动更新), local=需本地编译
RULE_SETS = [
    # ===== Aethersailor (本仓库) - 用 GitHub 上的 .srs 或编译 =====
    # 这些由本仓库 CI 生成（generate_rules.py 需要扩展或本地编译）
    # ===== senshinya (blackmatrix7 精选) - remote .srs =====
    ("Netflix", f"{CDN}/senshinya/singbox_ruleset@main/rule/Netflix/Netflix.srs"),
    ("YouTube", f"{CDN}/senshinya/singbox_ruleset@main/rule/YouTube/YouTube.srs"),
    ("Disney", f"{CDN}/senshinya/singbox_ruleset@main/rule/Disney/Disney.srs"),
    ("PrimeVideo", f"{CDN}/senshinya/singbox_ruleset@main/rule/PrimeVideo/PrimeVideo.srs"),
    ("HBO", f"{CDN}/senshinya/singbox_ruleset@main/rule/HBO/HBO.srs"),
    ("Hulu", f"{CDN}/senshinya/singbox_ruleset@main/rule/Hulu/Hulu.srs"),
    ("AppleTV", f"{CDN}/senshinya/singbox_ruleset@main/rule/AppleTV/AppleTV.srs"),
    ("TikTok", f"{CDN}/senshinya/singbox_ruleset@main/rule/TikTok/TikTok.srs"),
    ("Twitch", f"{CDN}/senshinya/singbox_ruleset@main/rule/Twitch/Twitch.srs"),
    ("Spotify", f"{CDN}/senshinya/singbox_ruleset@main/rule/Spotify/Spotify.srs"),
    # 游戏平台
    ("Steam", f"{CDN}/senshinya/singbox_ruleset@main/rule/Steam/Steam.srs"),
    ("Epic", f"{CDN}/senshinya/singbox_ruleset@main/rule/Epic/Epic.srs"),
    ("PlayStation", f"{CDN}/senshinya/singbox_ruleset@main/rule/PlayStation/PlayStation.srs"),
    ("Xbox", f"{CDN}/senshinya/singbox_ruleset@main/rule/Xbox/Xbox.srs"),
    ("Nintendo", f"{CDN}/senshinya/singbox_ruleset@main/rule/Nintendo/Nintendo.srs"),
    ("Riot", f"{CDN}/senshinya/singbox_ruleset@main/rule/Riot/Riot.srs"),
    # AI 平台
    ("OpenAI", f"{CDN}/senshinya/singbox_ruleset@main/rule/OpenAI/OpenAI.srs"),
    ("Anthropic", f"{CDN}/senshinya/singbox_ruleset@main/rule/Anthropic/Anthropic.srs"),
    ("Gemini", f"{CDN}/senshinya/singbox_ruleset@main/rule/Gemini/Gemini.srs"),
    ("Copilot", f"{CDN}/senshinya/singbox_ruleset@main/rule/Copilot/Copilot.srs"),
    # 大厂服务
    ("Google", f"{CDN}/senshinya/singbox_ruleset@main/rule/Google/Google.srs"),
    ("Apple", f"{CDN}/senshinya/singbox_ruleset@main/rule/Apple/Apple.srs"),
    ("Microsoft", f"{CDN}/senshinya/singbox_ruleset@main/rule/Microsoft/Microsoft.srs"),
    ("Amazon", f"{CDN}/senshinya/singbox_ruleset@main/rule/Amazon/Amazon.srs"),
    ("Adobe", f"{CDN}/senshinya/singbox_ruleset@main/rule/Adobe/Adobe.srs"),
    # ===== REIJI007 广告拦截 =====
    ("ads", f"{CDN}/REIJI007/AdBlock_Rule_For_Sing-box@main/adblock_reject.srs"),
    # ===== cmontage (clash yaml 转 srs) - 需要本地编译 =====
    # GFW/AI/Google/Netflix 已由 senshinya 覆盖，这里只补充 cmontage 特有
    ("GFW", f"{CDN}/cmontage/proxyrules-cm@main/Clash/PROXY/GFW.yaml"),
    # ===== Dreista 中国大陆 =====
    ("cn", f"{CDN}/Dreista/sing-box-rule-set-cn@rule-set/accelerated-domains.china.conf.srs"),
    ("cnip", f"{CDN}/Dreista/sing-box-rule-set-cn@rule-set/apnic-cn-ipv4.srs"),
    ("cn-gfw", f"{CDN}/Dreista/sing-box-rule-set-cn@rule-set/filter.txt.srs"),
]

# 策略组（outbounds）—— 基于 ShellCrash Full_BanAds 模板结构
def build_template():
    """构建 sing-box 完整模板 JSON"""
    # 策略组 outbounds
    outbounds = [
        {"tag": "🚀 节点选择", "type": "selector", "outbounds": ["♻️ 自动选择", "🎯 本地直连", "🇭🇰 香港节点", "🇺🇸 美国节点", "🇯🇵 日本节点", "🇸🇬 新加坡节点", "🇹🇼 台湾节点", "🇰🇷 韩国节点", "🐟 漏网之鱼"]},
        {"tag": "♻️ 自动选择", "type": "urltest", "interval": "2m", "use_all_providers": True},
        {"tag": "🤖 AI 平台", "type": "selector", "outbounds": ["🚀 节点选择", "🎯 本地直连"]},
        {"tag": "🎬 奈飞视频", "type": "selector", "outbounds": ["🚀 节点选择", "🎯 本地直连"]},
        {"tag": "▶️ 油管视频", "type": "selector", "outbounds": ["🚀 节点选择", "🎯 本地直连"]},
        {"tag": "🌍 国际媒体", "type": "selector", "outbounds": ["🚀 节点选择", "🎯 本地直连"]},
        {"tag": "🎮 外服游戏", "type": "selector", "outbounds": ["🚀 节点选择", "🎯 本地直连"]},
        {"tag": "🦾 Steam平台", "type": "selector", "outbounds": ["🎯 本地直连", "🚀 节点选择"]},
        {"tag": "🀄️ 国内流量", "type": "selector", "outbounds": ["🎯 本地直连", "🚀 节点选择"]},
        {"tag": "🛑 广告拦截", "type": "selector", "outbounds": ["⛔ 禁止连接", "🎯 本地直连"]},
        {"tag": "⛔ 禁止连接", "type": "block"},
        {"tag": "🎯 本地直连", "type": "direct"},
        {"tag": "🐟 漏网之鱼", "type": "selector", "outbounds": ["🚀 节点选择", "🎯 本地直连"]},
        {"tag": "GLOBAL", "type": "selector", "outbounds": ["🚀 节点选择", "🎯 本地直连"]},
        # 地区节点组
        {"tag": "🇭🇰 香港节点", "type": "urltest", "interval": "2m", "use_all_providers": True, "include": "(?i)(🇭🇰|港|hk|hongkong)"},
        {"tag": "🇺🇸 美国节点", "type": "urltest", "interval": "2m", "use_all_providers": True, "include": "(?i)(🇺🇸|美|us|united)"},
        {"tag": "🇯🇵 日本节点", "type": "urltest", "interval": "2m", "use_all_providers": True, "include": "(?i)(🇯🇵|日|jp|japan)"},
        {"tag": "🇸🇬 新加坡节点", "type": "urltest", "interval": "2m", "use_all_providers": True, "include": "(?i)(🇸🇬|新加坡|sg|singapore)"},
        {"tag": "🇹🇼 台湾节点", "type": "urltest", "interval": "2m", "use_all_providers": True, "include": "(?i)(🇹🇼|台|tw|taiwan)"},
        {"tag": "🇰🇷 韩国节点", "type": "urltest", "interval": "2m", "use_all_providers": True, "include": "(?i)(🇰🇷|韩|kr|korea)"},
    ]

    # 规则集定义
    rule_set_defs = []
    for tag, url in RULE_SETS:
        ext = url.split(".")[-1]
        is_srs = ext == "srs"
        rule_set_defs.append({
            "tag": tag,
            "type": "remote",
            "format": "binary" if is_srs else "source",
            "path": f"./ruleset/{tag}.srs" if is_srs else f"./ruleset/{tag}.json",
            "url": url,
        })

    # 路由规则（顺序：基础 → 国内直连 → 广告 → Aethersailor → 流媒体 → AI → 游戏 → 兜底）
    rules = [
        {"action": "sniff"},
        {"protocol": "dns", "action": "hijack-dns"},
        {"ip_is_private": True, "outbound": "🎯 本地直连"},
        {"protocol": "quic", "action": "reject", "no_drop": True},
        {"protocol": "bittorrent", "action": "reject"},
        # 国内直连优先
        {"rule_set": ["cn", "cnip"], "outbound": "🀄️ 国内流量"},
        # 广告拦截
        {"rule_set": ["ads"], "outbound": "🛑 广告拦截"},
        # GFW 拦截（Dreista filter.txt 是需代理的国内无法访问域名）
        # 流媒体
        {"rule_set": ["Netflix", "PrimeVideo", "HBO", "Hulu", "AppleTV"], "outbound": "🎬 奈飞视频"},
        {"rule_set": ["YouTube"], "outbound": "▶️ 油管视频"},
        {"rule_set": ["Disney", "TikTok", "Twitch", "Spotify"], "outbound": "🌍 国际媒体"},
        # AI 平台
        {"rule_set": ["OpenAI", "Anthropic", "Gemini", "Copilot"], "outbound": "🤖 AI 平台"},
        # 游戏
        {"rule_set": ["Steam"], "outbound": "🦾 Steam平台"},
        {"rule_set": ["Epic", "PlayStation", "Xbox", "Nintendo", "Riot"], "outbound": "🎮 外服游戏"},
        # 大厂服务（走代理）
        {"rule_set": ["Google", "Microsoft", "Amazon", "Adobe", "GFW"], "outbound": "🚀 节点选择"},
        {"rule_set": ["cn-gfw"], "outbound": "🚀 节点选择"},
        # 兜底
        {"outbound": "🐟 漏网之鱼"}
    ]

    template = {
        "outbounds": outbounds,
        "route": {
            "rules": rules,
            "rule_set": rule_set_defs,
            "final": "🐟 漏网之鱼"
        }
    }
    return template


def main():
    print(f"输出目录: {OUT_DIR}")
    os.makedirs(OUT_DIR, exist_ok=True)

    # 1. 生成模板
    template = build_template()
    template_path = os.path.join(OUT_DIR, "Custom_All.json")
    with open(template_path, "w", encoding="utf-8") as f:
        json.dump(template, f, ensure_ascii=False, indent=1)
    print(f"✅ 模板生成: {template_path} ({len(json.dumps(template))} bytes)")
    print(f"   规则集数: {len(template['route']['rule_set'])}")
    print(f"   策略组数: {len(template['outbounds'])}")
    print(f"   路由规则数: {len(template['route']['rules'])}")


if __name__ == "__main__":
    main()
