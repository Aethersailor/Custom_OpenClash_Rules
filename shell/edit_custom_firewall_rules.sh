#!/bin/sh

# 目标文件路径
TARGET_FILE="/etc/openclash/custom/openclash_custom_firewall_rules.sh"

# 要插入的内容
INSERT_CONTENT=$(cat << EOF
# ==============以下是广告过滤规则拉取脚本=================
LOG_OUT "拉取 anti-AD 广告过滤规则…"
# 注意自行核实 /tmp 下的 dnsmasq.d 文件夹名称，并修改对应代码  
curl -s https://anti-ad.net/anti-ad-for-dnsmasq.conf -o /tmp/dnsmasq.cfg01411c.d/anti-ad-for-dnsmasq.conf
# 广告过滤规则拉取脚本结束
# 以下是 GitHub520 加速规则拉取脚本
LOG_OUT "拉取 GitHub520 加速规则…"
sed -i '/# GitHub520 Host Start/,/# GitHub520 Host End/d' /etc/hosts
curl https://raw.hellogithub.com/hosts >> /etc/hosts
sed -i '/^$/d' /etc/hosts
sed -i '/!/d' /etc/hosts
# GitHub520 加速规则拉取脚本结束
# 清理 DNS 缓存，v0.46.043 之前版本无需此步骤
LOG_OUT "清理 DNS 缓存…"
#/etc/init.d/dnsmasq reload
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

echo "内容已成功清除并插入到 $TARGET_FILE 中！"