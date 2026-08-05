#!/usr/bin/env python3
"""Shared semantic contract for actively published configurations."""

RULESET_INTERVAL_SECONDS = 28_800

INI_PROFILE_PAIRS = (
    ("cfg/Custom_Clash.ini", "cfg/Custom_Clash_Fallback.ini"),
    ("cfg/Custom_Clash_Lite.ini", "cfg/Custom_Clash_Lite_Fallback.ini"),
    ("cfg/Custom_Clash_Full.ini", "cfg/Custom_Clash_Full_Fallback.ini"),
    ("cfg/Custom_Clash_GFW.ini", "cfg/Custom_Clash_GFW_Fallback.ini"),
)

YAML_PROFILE_PAIRS = (
    ("cfg/yaml/Custom_Clash.yaml", "cfg/yaml/Custom_Clash_Fallback.yaml"),
    ("cfg/yaml/Custom_Clash_Lite.yaml", "cfg/yaml/Custom_Clash_Lite_Fallback.yaml"),
    ("cfg/yaml/Custom_Clash_Full.yaml", "cfg/yaml/Custom_Clash_Full_Fallback.yaml"),
    ("cfg/yaml/Custom_Clash_GFW.yaml", "cfg/yaml/Custom_Clash_GFW_Fallback.yaml"),
)

STANDALONE_YAML_CONFIGS = (
    "cfg/yaml/Complete_YAML_Configuration_Template.yaml",
    "cfg/yaml/Custom_Clash_Selfhosted_Manual_Fallback.yaml",
    "cfg/yaml/Custom_Clash_Selfhosted_Provider_Fallback.yaml",
)

DERIVED_CONFIGS = (
    ("cfg/Custom_Clash.ini", "cfg/Custom_Clash_Mainland.ini"),
)

FALLBACK_POLICY_MAP = {
    "🚀 故障转移": "🚀 手动选择",
}

BUILTIN_POLICIES = frozenset(
    {
        "DIRECT",
        "REJECT",
        "REJECT-DROP",
        "PASS",
        "GLOBAL",
    }
)

REQUIRED_RULES = {
    "cfg/Custom_Clash_Full.ini": (
        "🪙 加密货币,[]GEOSITE,category-cryptocurrency",
    ),
    "cfg/Custom_Clash_Full_Fallback.ini": (
        "🪙 加密货币,[]GEOSITE,category-cryptocurrency",
    ),
    "cfg/yaml/Custom_Clash_Full.yaml": (
        "GEOSITE,category-cryptocurrency,🪙 加密货币",
    ),
    "cfg/yaml/Custom_Clash_Full_Fallback.yaml": (
        "GEOSITE,category-cryptocurrency,🪙 加密货币",
    ),
}

INI_TO_YAML_PROFILES = (
    ("cfg/Custom_Clash.ini", "cfg/yaml/Custom_Clash.yaml"),
    ("cfg/Custom_Clash_Fallback.ini", "cfg/yaml/Custom_Clash_Fallback.yaml"),
    ("cfg/Custom_Clash_Lite.ini", "cfg/yaml/Custom_Clash_Lite.yaml"),
    ("cfg/Custom_Clash_Lite_Fallback.ini", "cfg/yaml/Custom_Clash_Lite_Fallback.yaml"),
    ("cfg/Custom_Clash_Full.ini", "cfg/yaml/Custom_Clash_Full.yaml"),
    ("cfg/Custom_Clash_Full_Fallback.ini", "cfg/yaml/Custom_Clash_Full_Fallback.yaml"),
    ("cfg/Custom_Clash_GFW.ini", "cfg/yaml/Custom_Clash_GFW.yaml"),
    ("cfg/Custom_Clash_GFW_Fallback.ini", "cfg/yaml/Custom_Clash_GFW_Fallback.yaml"),
)


def flatten_pairs(pairs: tuple[tuple[str, str], ...]) -> tuple[str, ...]:
    return tuple(item for pair in pairs for item in pair)


ACTIVE_INI_CONFIGS = flatten_pairs(INI_PROFILE_PAIRS) + (
    "cfg/Custom_Clash_Mainland.ini",
)
ACTIVE_YAML_CONFIGS = flatten_pairs(YAML_PROFILE_PAIRS) + STANDALONE_YAML_CONFIGS
