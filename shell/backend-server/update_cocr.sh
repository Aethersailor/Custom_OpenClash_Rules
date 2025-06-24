#!/bin/bash

BASE_DIR="/etc/subconverter_public/Custom_OpenClash_Rules"
RULE_DIR="$BASE_DIR/rules"
LOG_FILE="/var/log/openclash_rule_update.log"
LOCK_FILE="/tmp/openclash_rule_update.lock"

exec >> "$LOG_FILE" 2>&1
exec 200>"$LOCK_FILE"
flock -n 200 || { echo "[$(date '+%F %T')] 已有一个实例在运行，退出"; exit 1; }

echo "[$(date '+%F %T')] 开始更新规则文件..."

mkdir -p "$RULE_DIR"

download_file() {
    local url="$1"
    local dest="$2"
    echo "[$(date '+%F %T')] 下载 $url 到 $dest"
    if curl -fsSL --retry 3 --retry-delay 5 "$url" -o "$dest"; then
        echo "[$(date '+%F %T')] ✓ 成功：$dest"
    else
        echo "[$(date '+%F %T')] ✗ 失败：$url"
    fi
}

# 下载规则文件
download_file "https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/rule/Custom_Direct.list" "$RULE_DIR/Custom_Direct.list"
download_file "https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/rule/Custom_Proxy.list" "$RULE_DIR/Custom_Proxy.list"
download_file "https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/rule/Steam_CDN.list" "$RULE_DIR/Steam_CDN.list"

# 下载配置文件
download_file "https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/cfg/Custom_Clash.ini" "$BASE_DIR/Custom_Clash.ini"
download_file "https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/cfg/Custom_Clash_Full.ini" "$BASE_DIR/Custom_Clash_Full.ini"
download_file "https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/cfg/Custom_Clash_GFW.ini" "$BASE_DIR/Custom_Clash_GFW.ini"
download_file "https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/cfg/Custom_Clash_Lite.ini" "$BASE_DIR/Custom_Clash_Lite.ini"

# 下载并修改Custom_Clash_Mainland.ini
MAINLAND_FILE="$BASE_DIR/Custom_Clash_Mainland.ini"
download_file "https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/cfg/Custom_Clash_Mainland.ini" "$MAINLAND_FILE"

# 修改规则内容
echo "[$(date '+%F %T')] 正在修改 $MAINLAND_FILE 中的规则路径..."

# 规则替换函数：只保留逗号前规则名与目标路径
sed -i \
  -e '/Custom_Direct.list/s#^ruleset=🎯 全球直连,[^,]*.*#ruleset=🎯 全球直连,rules/Custom_OpenClash_Rules/Custom_Direct.list#' \
  -e '/Custom_Proxy.list/s#^ruleset=🚀 手动选择,[^,]*.*#ruleset=🚀 手动选择,rules/Custom_OpenClash_Rules/Custom_Proxy.list#' \
  -e '/Steam_CDN.list/s#^ruleset=🎯 全球直连,[^,]*.*#ruleset=🎯 全球直连,rules/Custom_OpenClash_Rules/Steam_CDN.list#' \
  "$MAINLAND_FILE"

echo "[$(date '+%F %T')] Custom_Clash_Mainland.ini 修改完成。"
echo "[$(date '+%F %T')] 所有操作完成。"
