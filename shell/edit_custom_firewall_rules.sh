#!/bin/sh
# 清空屏幕并显示欢迎信息
clear
sleep 1
echo "##########################################################"
echo "#                Custom_OpenClash_Rules                  #"
echo "# https://github.com/Aethersailor/Custom_OpenClash_Rules #"
echo "##########################################################"
sleep 1
echo "广告过滤规则设置脚本开始运行..."
sleep 1
echo "开始修改 OpenClash 开发者选项..."
sleep 1

# ---------------------------
# 步骤1：询问是否启用广告过滤功能（即时响应，不需回车）
# ---------------------------
while true; do
    read -n 1 -p "是否启用广告过滤功能？(y=是，n=否): " adv_choice
    echo ""
    adv_choice=$(echo "$adv_choice" | tr '[:upper:]' '[:lower:]')
    if [ "$adv_choice" = "y" ] || [ "$adv_choice" = "n" ]; then
        break
    else
        echo "输入错误，请重新输入"
    fi
done
sleep 1

# 如果启用了广告过滤，询问具体规则选择（即时响应）
if [ "$adv_choice" = "y" ]; then
    while true; do
        echo "请选择要启用的广告过滤规则："
        echo "1. anti-ad 规则"
        echo "2. adblockfilters 原版规则"
        echo "3. adblockfilters-modified 规则"
        echo "4. 秋风广告规则"
        read -n 1 -p "请输入(单选): " ad_rule
        echo ""
        if [ "$ad_rule" = "1" ] || [ "$ad_rule" = "2" ] || [ "$ad_rule" = "3" ] || [ "$ad_rule" = "4" ]; then
            break
        else
            echo "输入错误，请重新输入"
        fi
    done
    sleep 1
fi

# ---------------------------
# 步骤2：询问是否启用 Github520 Hosts 加速规则（即时响应）
# ---------------------------
while true; do
    read -n 1 -p "是否启用 Github520 Hosts 加速规则？(y=是，n=否): " github_choice
    echo ""
    github_choice=$(echo "$github_choice" | tr '[:upper:]' '[:lower:]')
    if [ "$github_choice" = "y" ] || [ "$github_choice" = "n" ]; then
        break
    else
        echo "输入错误，请重新输入"
    fi
done
sleep 1

echo "开始修改开发者选项..."
sleep 1

# ---------------------------
# 定义目标文件路径（请确保该路径正确）
# ---------------------------
TARGET_FILE="/etc/openclash/custom/openclash_custom_firewall_rules.sh"

# 检查目标文件是否存在
if [ ! -f "$TARGET_FILE" ]; then
    echo "目标文件不存在: $TARGET_FILE"
    exit 1
fi

# ---------------------------
# 构造新的插入内容（开发者选项部分）
# 仅在至少启用一项功能时构造内容；否则保持为空
# ---------------------------
NEW_INSERT_CONTENT=""
if [ "$adv_choice" = "y" ] || [ "$github_choice" = "y" ]; then
    NEW_INSERT_CONTENT="# ==============以下是广告过滤规则拉取脚本=================
(
    VERSION=\"1.5\"
    MAX_WAIT_TIME=30
    WAIT_INTERVAL=2
    elapsed_time=0

    if /etc/init.d/openclash status | grep -q \"Syntax:\"; then
        LOG_OUT \"[广告过滤规则拉取脚本] 当前版本 \$VERSION，正在检测 OpenClash 运行状态...\"
        LOG_OUT \"[广告过滤规则拉取脚本] 等待 10 秒以确保 OpenClash 已启动...\"
        sleep 10
    else
        LOG_OUT \"[广告过滤规则拉取脚本] 当前版本 \$VERSION，正在检测 OpenClash 运行状态...\"
        while ! /etc/init.d/openclash status | grep -q \"running\"; do
            if [ \$elapsed_time -ge \$MAX_WAIT_TIME ]; then
                LOG_OUT \"[广告过滤规则拉取脚本] 未能在 30 秒内检测到 OpenClash 运行状态，脚本已停止运行...\"
                exit 1
            fi
            sleep \$WAIT_INTERVAL
            elapsed_time=\$((elapsed_time + WAIT_INTERVAL))
        done
        LOG_OUT \"[广告过滤规则拉取脚本] 检测到 OpenClash 正在运行，10 秒后开始拉取规则...\"
        sleep 10
    fi

    # 动态选择 dnsmasq 目录
    LOG_OUT \"[广告过滤规则拉取脚本] 开始检测 dnsmasq 规则目录...\"
    UCI_OUTPUT=\$(uci show dhcp.@dnsmasq[0] 2>/dev/null)
    
    # 检测新版固件（哈希值模式）
    if echo \"\$UCI_OUTPUT\" | grep -qE 'cfg[0-9a-f]{6}'; then
        HASH_ID=\$(echo \"\$UCI_OUTPUT\" | grep -oE 'cfg[0-9a-f]{6}' | head -1)
        TARGET_DIR=\"/tmp/dnsmasq.\${HASH_ID}.d\"
        LOG_OUT \"[广告过滤规则拉取脚本] 当前 dnsmasq 规则目录: \$TARGET_DIR\"
    # 检测旧版固件（数字索引模式）
    elif echo \"\$UCI_OUTPUT\" | grep -qE '@dnsmasq\\[[0-9]+\\]'; then
        TARGET_DIR=\"/tmp/dnsmasq.d\"
        LOG_OUT \"[广告过滤规则拉取脚本] 当前dnsmasq 规则目录: \$TARGET_DIR\"
    # 兼容性回退
    else
        TARGET_DIR=\$(find /tmp -maxdepth 1 -type d -name \"dnsmasq.*.d\" | head -n 1)
        if [ -z \"\$TARGET_DIR\" ]; then
            LOG_OUT \"[广告过滤规则拉取脚本] 错误：未找到有效的 dnsmasq 规则目录，脚本已停止！\"
            exit 1
        fi
        LOG_OUT \"[广告过滤规则拉取脚本] 检测失败，使用已存在的 dnsmasq 规则目录: \$TARGET_DIR\"
    fi
    
    # 验证目录存在性
    if [ ! -d \"\$TARGET_DIR\" ]; then
        mkdir -p \"\$TARGET_DIR\"
    fi

    # 输出清除已有的广告过滤规则的日志
    LOG_OUT \"[广告过滤规则拉取脚本] 清除已有规则…\"
    # 仅删除当前目标目录的广告规则文件
    rm -f \"\$TARGET_DIR\"/*ad*.conf
    sed -i '/# AWAvenue-Ads-Rule Start/,/# AWAvenue-Ads-Rule End/d' /etc/hosts
    sed -i '/# GitHub520 Host Start/,/# GitHub520 Host End/d' /etc/hosts
"  # 注意保留原有结尾双引号
    if [ "$adv_choice" = "y" ]; then
        case "$ad_rule" in
            1)
                NEW_INSERT_CONTENT="${NEW_INSERT_CONTENT}
    LOG_OUT \"[广告过滤规则拉取脚本] 拉取最新的 anti-AD 广告过滤规则，规则体积较大，请耐心等候…\"
    curl -sS -4 -L --retry 10 --retry-delay 2 \\
        \"https://testingcf.jsdelivr.net/gh/privacy-protection-tools/anti-AD@refs/heads/master/adblock-for-dnsmasq.conf\" \\
        -o \"\$TARGET_DIR/anti-ad-for-dnsmasq.conf\" >/dev/null 2>/tmp/anti-ad-curl.log
    CURL_EXIT=\$?

    if [ \$CURL_EXIT -eq 0 ]; then
        LOG_OUT \"[广告过滤规则拉取脚本] anti-AD 规则拉取成功！保存路径：\${TARGET_DIR}/anti-ad-for-dnsmasq.conf\"
    else
        LOG_OUT \"[广告过滤规则拉取脚本] anti-AD 规则拉取失败 (错误码:\$CURL_EXIT)，查看 /tmp/anti-ad-curl.log 获取详细信息。\"
        echo \"CURL Exit Code: \$CURL_EXIT\" >> /tmp/anti-ad-curl.log
    fi
"
                ;;
            2)
                NEW_INSERT_CONTENT="${NEW_INSERT_CONTENT}
    LOG_OUT \"[广告过滤规则拉取脚本] 拉取最新的 adblockfilters 广告过滤规则，规则体积较大，请耐心等候…\"
    curl -sS -4 -L --retry 10 --retry-delay 2 \\
        \"https://testingcf.jsdelivr.net/gh/217heidai/adblockfilters@refs/heads/main/rules/adblockdnsmasq.txt\" \\
        -o \"\$TARGET_DIR/adblockfilters-for-dnsmasq.conf\" >/dev/null 2>/tmp/adblockfilters-curl.log
    CURL_EXIT=\$?

    if [ \$CURL_EXIT -eq 0 ]; then
        LOG_OUT \"[广告过滤规则拉取脚本] adblockfilters 规则拉取成功！保存路径：\${TARGET_DIR}/adblockfilters-for-dnsmasq.conf\"
    else
        LOG_OUT \"[广告过滤规则拉取脚本] adblockfilters 规则拉取失败 (错误码:\$CURL_EXIT)，查看 /tmp/adblockfilters-curl.log 获取详细信息。\"
        echo \"CURL Exit Code: \$CURL_EXIT\" >> /tmp/adblockfilters-curl.log
    fi
"
                ;;
            3)
                NEW_INSERT_CONTENT="${NEW_INSERT_CONTENT}
    LOG_OUT \"[广告过滤规则拉取脚本] 拉取最新的 adblockfilters-modified 广告过滤规则...\"
    curl -sS -4 -L --retry 10 --retry-delay 2 \\
        \"https://testingcf.jsdelivr.net/gh/Aethersailor/adblockfilters-modified@refs/heads/main/rules/adblockdnsmasq.txt\" \\
        -o \"\$TARGET_DIR/adblockfilters-modified-for-dnsmasq.conf\" >/dev/null 2>/tmp/adblockfilters-modified-curl.log
    CURL_EXIT=\$?

    if [ \$CURL_EXIT -eq 0 ]; then
        LOG_OUT \"[广告过滤规则拉取脚本] adblockfilters-modified 规则拉取成功！保存路径：\${TARGET_DIR}/adblockfilters-modified-for-dnsmasq.conf\"
    else
        LOG_OUT \"[广告过滤规则拉取脚本] adblockfilters-modified 规则拉取失败 (错误码:\$CURL_EXIT)，查看 /tmp/adblockfilters-modified-curl.log 获取详细信息。\"
        echo \"CURL Exit Code: \$CURL_EXIT\" >> /tmp/adblockfilters-modified-curl.log
    fi
"
                ;;
            4)
                NEW_INSERT_CONTENT="${NEW_INSERT_CONTENT}
    LOG_OUT \"[广告过滤规则拉取脚本] 拉取最新的 秋风广告规则...\"
    curl -sSL -4 --retry 10 --retry-delay 2 https://testingcf.jsdelivr.net/gh/TG-Twilight/AWAvenue-Ads-Rule@main/Filters/AWAvenue-Ads-Rule-hosts.txt | \\
    sed '/127.0.0.1 localhost/d; /::1 localhost/d; 1s/^/# AWAvenue-Ads-Rule Start\\n/; \$s/\$/\\n# AWAvenue-Ads-Rule End/' >> /etc/hosts
"
                ;;
        esac
    fi
    if [ "$github_choice" = "y" ]; then
        NEW_INSERT_CONTENT="${NEW_INSERT_CONTENT}
    LOG_OUT \"[广告过滤规则拉取脚本] 拉取最新的 GitHub520 加速规则…\"
    curl -4 -sSL --retry 10 --retry-delay 2 \\
        \"https://raw.hellogithub.com/hosts\" >> /etc/hosts 2>/tmp/github520-curl.log
    CURL_EXIT_GH=\$?

    if [ \$CURL_EXIT_GH -eq 0 ]; then
        LOG_OUT \"[广告过滤规则拉取脚本] GitHub520 加速规则拉取成功！已追加到 /etc/hosts 文件中。\"
    else
        LOG_OUT \"[广告过滤规则拉取脚本] GitHub520 加速规则拉取失败 (错误码:\$CURL_EXIT_GH)，查看 /tmp/github520-curl.log 获取详细信息。\"
        echo \"CURL Exit Code: \$CURL_EXIT_GH\" >> /tmp/github520-curl.log
    fi
"
    fi
    NEW_INSERT_CONTENT="${NEW_INSERT_CONTENT}
    LOG_OUT \"[广告过滤规则拉取脚本] 清理 DNS 缓存...\"
    /etc/init.d/dnsmasq stop
    /etc/init.d/dnsmasq start
    LOG_OUT \"[广告过滤规则拉取脚本] 脚本运行完毕!\"

) &
# ==============广告过滤规则拉取脚本结束=============="
fi

# ---------------------------
# 确保目标文件以换行符结尾
# ---------------------------
sed -i -e '$a\' "$TARGET_FILE"

########################################################################
# 清除目标文件中已有的开发者选项内容
# 删除从完全匹配标记行到完全匹配 exit 0 之间的内容
########################################################################
awk '
/^[[:space:]]*LOG_OUT "Tip: Start Add Custom Firewall Rules\.\.\."[[:space:]]*$/ {
    print; inblock=1; next
}
 
/^[[:space:]]*exit 0[[:space:]]*$/ {
    if (inblock) { print; inblock=0; next }
}
 
{ if (!inblock) print }
' "$TARGET_FILE" > "${TARGET_FILE}.tmp" && mv "${TARGET_FILE}.tmp" "$TARGET_FILE"
sleep 1

########################################################################
# 清除旧规则（针对其他规则文件及 hosts 中已存在的规则）
########################################################################
echo "清除已有的规则文件..."
rm -f /tmp/dnsmasq.d/*ad*.conf
rm -f /tmp/dnsmasq.cfg01411c.d/*ad*.conf
sed -i '/# AWAvenue-Ads-Rule Start/,/# AWAvenue-Ads-Rule End/d' /etc/hosts
sed -i '/# GitHub520 Host Start/,/# GitHub520 Host End/d' /etc/hosts
sleep 1

########################################################################
# 将新的开发者选项内容插入到目标文件中
# 在匹配到完全的标记行后插入 NEW_INSERT_CONTENT（如果非空）
########################################################################
if [ -n "$NEW_INSERT_CONTENT" ]; then
    awk -v content="$NEW_INSERT_CONTENT" '
    /^[[:space:]]*LOG_OUT "Tip: Start Add Custom Firewall Rules\.\.\."[[:space:]]*$/ {
        print; print content; next
    }
    { print }
    ' "$TARGET_FILE" > "${TARGET_FILE}.tmp" && mv "${TARGET_FILE}.tmp" "$TARGET_FILE"
fi
sleep 1

########################################################################
# 对目标文件中 exit 0 后的空行进行处理：确保 exit 0 后最多只有一个空行
########################################################################
sed -i ':a;N;$!ba;s/\(exit 0\)\n\{2,\}/\1\n/' "$TARGET_FILE"

########################################################################
# 根据用户选择构造并输出总结提示
########################################################################
# 设置 ANSI 颜色
GREEN="\033[32m"
RED="\033[31m"
NC="\033[0m"  # No Color

if [ "$adv_choice" = "y" ]; then
    ad_status="${GREEN}已启用${NC}"
    case "$ad_rule" in
        1)
            rule_name="${GREEN}anti-ad 规则${NC}"
            ;;
        2)
            rule_name="${GREEN}adblockfilters 原版规则${NC}"
            ;;
        3)
            rule_name="${GREEN}adblockfilters-modified 规则${NC}"
            ;;
        4)
            rule_name="${GREEN}秋风广告规则${NC}"
            ;;
    esac
else
    ad_status="${RED}未启用${NC}"
fi

if [ "$github_choice" = "y" ]; then
    github_status="${GREEN}已启用${NC}"
else
    github_status="${RED}未启用${NC}"
fi
echo "OpenClash 开发者选项修改成功！"
sleep 1
echo "##########################################################"
echo -e "广告过滤规则：$ad_status"
if [ "$adv_choice" = "y" ]; then
    echo -e "启用规则：$rule_name"
fi
echo -e "Github520 Hosts 加速规则：$github_status"
echo "##########################################################"
sleep 1
echo "所有旧规则已清除，新的规则拉取设置将在 OpenClash 下次启动后生效"
sleep 1
echo "脚本退出..."
sleep 1
