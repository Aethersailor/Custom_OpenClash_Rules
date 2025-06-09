#!/bin/sh

# 目标文件路径
TARGET_FILE="/etc/openclash/custom/openclash_custom_firewall_rules.sh"

# 要插入的内容
INSERT_CONTENT=$(cat << 'EOF'
# ==============以下是广告过滤规则拉取脚本=================
(
    VERSION="1.5"
    MAX_WAIT_TIME=30
    WAIT_INTERVAL=2
    elapsed_time=0

    if /etc/init.d/openclash status | grep -q "Syntax:"; then
        LOG_OUT "[广告过滤规则拉取脚本] 当前版本 $VERSION，正在检测 OpenClash 运行状态..."
        LOG_OUT "[广告过滤规则拉取脚本] 等待 10 秒以确保 OpenClash 已启动..."
        sleep 10
    else
        LOG_OUT "[广告过滤规则拉取脚本] 当前版本 $VERSION，正在检测 OpenClash 运行状态..."
        while ! /etc/init.d/openclash status | grep -q "running"; do
            if [ $elapsed_time -ge $MAX_WAIT_TIME ]; then
                LOG_OUT "[广告过滤规则拉取脚本] 未能在 30 秒内检测到 OpenClash 运行状态，脚本已停止运行..."
                exit 1
            fi
            sleep $WAIT_INTERVAL
            elapsed_time=$((elapsed_time + WAIT_INTERVAL))
        done
        LOG_OUT "[广告过滤规则拉取脚本] 检测到 OpenClash 正在运行，10 秒后开始拉取规则..."
        sleep 10
    fi

    # 动态选择 dnsmasq 目录
    LOG_OUT "[广告过滤规则拉取脚本] 开始检测 dnsmasq 规则目录..."
    # 通过 uci 命令获取配置标识符
    UCI_OUTPUT=$(uci show dhcp.@dnsmasq[0] 2>/dev/null)
    
    # 检测新版固件（哈希值模式）
    if echo "$UCI_OUTPUT" | grep -qE 'cfg[0-9a-f]{6}'; then
        HASH_ID=$(echo "$UCI_OUTPUT" | grep -oE 'cfg[0-9a-f]{6}' | head -1) 
        TARGET_DIR="/tmp/dnsmasq.${HASH_ID}.d"
        LOG_OUT "[广告过滤规则拉取脚本] 当前 dnsmasq 规则目录: $TARGET_DIR"
    # 检测旧版固件（数字索引模式）
    elif echo "$UCI_OUTPUT" | grep -qE '@dnsmasq\[[0-9]+\]'; then
        TARGET_DIR="/tmp/dnsmasq.d"
        LOG_OUT "[广告过滤规则拉取脚本] 当前dnsmasq 规则目录: $TARGET_DIR"
    # 兼容性回退
    else
        TARGET_DIR=$(find /tmp -maxdepth 1 -type d -name "dnsmasq.*.d" | head -n 1)
        if [ -z "$TARGET_DIR" ]; then
            LOG_OUT "[广告过滤规则拉取脚本] 错误：未找到有效的 dnsmasq 规则目录，脚本已停止！"
            exit 1
        fi
        LOG_OUT "[广告过滤规则拉取脚本] 检测失败，使用已存在的 dnsmasq 规则目录: $TARGET_DIR"
    fi
    
    # 验证目录存在性
    if [ ! -d "$TARGET_DIR" ]; then
        mkdir -p "$TARGET_DIR"
    fi

    # 输出清除已有的广告过滤规则的日志
    LOG_OUT "[广告过滤规则拉取脚本] 清除已有规则…"
    # 删除 dnsmasq 格式的广告过滤规则
    rm -f "$TARGET_DIR"/*ad*.conf 
    # 删除 hosts 格式的广告过滤规则
    sed -i '/# AWAvenue-Ads-Rule Start/,/# AWAvenue-Ads-Rule End/d' /etc/hosts
    sed -i '/# GitHub520 Host Start/,/# GitHub520 Host End/d' /etc/hosts

    # 输出拉取最新的 anti-AD 广告过滤规则的日志
    LOG_OUT "[广告过滤规则拉取脚本] 拉取最新的 anti-AD 广告过滤规则，规则体积较大，请耐心等候…"
    # 下载 anti-AD 规则到动态选择的目录
    curl -sS -4 -L --retry 10 --retry-delay 2 \
        "https://testingcf.jsdelivr.net/gh/privacy-protection-tools/anti-AD@refs/heads/master/adblock-for-dnsmasq.conf" \
        -o "$TARGET_DIR/anti-ad-for-dnsmasq.conf" >/dev/null 2>/tmp/anti-ad-curl.log
    CURL_EXIT=$?

    # 检查 curl 命令是否成功
    if [ $CURL_EXIT -eq 0 ]; then
        LOG_OUT "[广告过滤规则拉取脚本] anti-AD 规则拉取成功！保存路径：${TARGET_DIR}/anti-ad-for-dnsmasq.conf"
    else
        # 如果失败，输出拉取失败的日志，并提示查看日志文件获取详细信息
        LOG_OUT "[广告过滤规则拉取脚本] anti-AD 规则拉取失败 (错误码:$CURL_EXIT)，查看 /tmp/anti-ad-curl.log 获取详细信息。"
        echo "CURL Exit Code: $CURL_EXIT" >> /tmp/anti-ad-curl.log
    fi

    LOG_OUT "[广告过滤规则拉取脚本] 拉取最新的 GitHub520 加速规则…"
    curl -4 -sSL --retry 10 --retry-delay 2 \
        "https://raw.hellogithub.com/hosts" >> /etc/hosts 2>/tmp/github520-curl.log
    CURL_EXIT_GH=$?

    if [ $CURL_EXIT_GH -eq 0 ]; then
        LOG_OUT "[广告过滤规则拉取脚本] GitHub520 加速规则拉取成功！已追加到 /etc/hosts 文件中。"
    else
        LOG_OUT "[广告过滤规则拉取脚本] GitHub520 加速规则拉取失败 (错误码:$CURL_EXIT_GH)，查看 /tmp/github520-curl.log 获取详细信息。"
        echo "CURL Exit Code: $CURL_EXIT_GH" >> /tmp/github520-curl.log
    fi

    sed -i '/^$/d' /etc/hosts
    sed -i '/!/d' /etc/hosts

    LOG_OUT "[广告过滤规则拉取脚本] 重新加载 dnsmasq 服务以应用规则…"
    /etc/init.d/dnsmasq stop
    /etc/init.d/dnsmasq start
    LOG_OUT "[广告过滤规则拉取脚本] 脚本运行完毕！"

) &
# ==============广告过滤规则拉取脚本结束==============
EOF
)

# 检查目标文件是否存在
if [ ! -f "$TARGET_FILE" ]; then
  echo "目标文件不存在: $TARGET_FILE"
  exit 1
fi

# 确保目标文件以换行符结尾
sed -i -e '$a\' "$TARGET_FILE"

# 清除指定范围内容（LOG_OUT 到 exit 0 之间的内容）
awk '
BEGIN {skip=0}
/LOG_OUT "Tip: Start Add Custom Firewall Rules..."/ {print; skip=1; next}
/exit 0/ {skip=0}
!skip
' "$TARGET_FILE" > "${TARGET_FILE}.tmp" && mv "${TARGET_FILE}.tmp" "$TARGET_FILE"

# 插入新内容
awk -v content="$INSERT_CONTENT" '
/LOG_OUT "Tip: Start Add Custom Firewall Rules..."/ {
    print;
    print content;
    next;
}
1
' "$TARGET_FILE" > "${TARGET_FILE}.tmp" && mv "${TARGET_FILE}.tmp" "$TARGET_FILE"

echo "anti-ad 广告过滤规则和 Github520 Hosts 拉取代码已写入到“开发者选项”文件 $TARGET_FILE 中，并将在 OpenClash 下次启动时生效！"
