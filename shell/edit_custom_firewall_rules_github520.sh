#!/bin/sh

# 目标文件路径
TARGET_FILE="/etc/openclash/custom/openclash_custom_firewall_rules.sh"

# 要插入的内容
INSERT_CONTENT=$(cat << EOF
# ==============以下是广告过滤规则拉取脚本=================
(
    MAX_WAIT_TIME=30
    WAIT_INTERVAL=2
    elapsed_time=0

    if /etc/init.d/openclash status | grep -q "Syntax:"; then
        LOG_OUT "[广告过滤规则拉取脚本] 等待 10 秒以确保 OpenClash 已启动..."
        sleep 10
    else
        while ! /etc/init.d/openclash status | grep -q "running"; do
            if [ $elapsed_time -ge $MAX_WAIT_TIME ]; then
                LOG_OUT "[广告过滤规则拉取脚本] 未能在 30 秒内检测到 OpenClash 运行状态，脚本已停止运行..."
                exit 1
            fi
            LOG_OUT "[广告过滤规则拉取脚本] 正在检测 OpenClash 运行状态，请稍后..."
            sleep $WAIT_INTERVAL
            elapsed_time=$((elapsed_time + WAIT_INTERVAL))
        done
        LOG_OUT "[广告过滤规则拉取脚本] 检测到 OpenClash 正在运行，10 秒后开始拉取规则..."
        sleep 10
    fi

    LOG_OUT "[广告过滤规则拉取脚本] 清除已有的 GitHub520 加速规则…"
    sed -i '/# GitHub520 Host Start/,/# GitHub520 Host End/d' /etc/hosts
    
    LOG_OUT "[广告过滤规则拉取脚本] 清除广告过滤规则…"
    rm -f /tmp/dnsmasq.d/*ad*.conf
    rm -f /tmp/dnsmasq.cfg01411c.d/*ad*.conf
    sed -i '/# AWAvenue-Ads-Rule Start/,/# AWAvenue-Ads-Rule End/d' /etc/hosts

    LOG_OUT "[广告过滤规则拉取脚本] 拉取最新的 GitHub520 加速规则…"
    curl -sSL -4 --retry 5 --retry-delay 1 "https://raw.hellogithub.com/hosts" >> /etc/hosts 2> /tmp/github520-curl.log

    if [ $? -eq 0 ]; then
        LOG_OUT "[广告过滤规则拉取脚本] GitHub520 加速规则拉取成功！"
    else
        LOG_OUT "[广告过滤规则拉取脚本] GitHub520 加速规则拉取失败，查看 /tmp/github520-curl.log 获取详细信息。"
    fi

    sed -i '/^$/d' /etc/hosts
    sed -i '/!/d' /etc/hosts

    LOG_OUT "[广告过滤规则拉取脚本] 清理 DNS 缓存…"
    /etc/init.d/dnsmasq reload
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

echo "Github520 Hosts 拉取代码已写入到“开发者选项”文件 $TARGET_FILE 中，并将在 OpenClash 下次启动时生效！"
