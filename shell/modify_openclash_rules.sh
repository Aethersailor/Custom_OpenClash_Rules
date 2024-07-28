#!/bin/sh

# 进入脚本的主函数
main() {
    # 提示用户脚本开始执行
    echo "OpenClash 开发者选项修改脚本开始执行"

    # 定义目标文件路径
    TARGET_FILE="/etc/openclash/custom/openclash_custom_firewall_rules.sh"

    # 备份原始文件
    cp "$TARGET_FILE" "${TARGET_FILE}.bak"

    # 清除现有规则拉取指令
    sed -i '/# 以下是广告过滤规则拉取脚本/,/# 广告过滤规则拉取脚本结束/d' "$TARGET_FILE"
    sed -i '/# 以下是 GitHub520 加速规则拉取脚本/,/# GitHub520 加速规则拉取脚本结束/d' "$TARGET_FILE"
    sed -i '/curl/d; /sed/d; /---/d' "$TARGET_FILE"
    echo "规则拉取命令已清空！"

    # 清除文件中的空行
    sed -i '/^$/d' "$TARGET_FILE"

    # 删除文件中的 exit 0
    sed -i '/^exit 0$/d' "$TARGET_FILE"

    # 询问用户选择的广告过滤规则
    while true; do
        echo "请选择要添加的广告过滤规则："
        echo "1：anti-AD"
        echo "2：秋风广告规则"
        read -p "请输入选项并回车：" OPTION

        case "$OPTION" in
            1)
                # 添加 anti-AD 广告过滤规则
                echo "# 以下是广告过滤规则拉取脚本" >> "$TARGET_FILE"
                echo "LOG_OUT \"拉取 anti-AD 广告过滤规则…\"" >> "$TARGET_FILE"
                echo "curl -s https://anti-ad.net/anti-ad-for-dnsmasq.conf -o /tmp/dnsmasq.d/anti-ad-for-dnsmasq.conf" >> "$TARGET_FILE"
                echo "# 广告过滤规则拉取脚本结束" >> "$TARGET_FILE"
                echo "已添加 anti-AD 广告过滤规则！"
                break
                ;;
            2)
                # 添加 秋风广告规则
                echo "# 以下是广告过滤规则拉取脚本" >> "$TARGET_FILE"
                echo "LOG_OUT \"拉取秋风广告过滤规则…\"" >> "$TARGET_FILE"
                echo "sed -i '/# AWAvenue-Ads-Rule Start/,/# AWAvenue-Ads-Rule End/d' /etc/hosts" >> "$TARGET_FILE"
                echo "curl https://github.tmby.shop/https://raw.githubusercontent.com/TG-Twilight/AWAvenue-Ads-Rule/main/AWAvenue-Ads-Rule.txt | \\" >> "$TARGET_FILE"
                echo "    sed '/127.0.0.1 localhost/d; /::1 localhost/d; 1s/^/# AWAvenue-Ads-Rule Start\\n/; \$s/\$/\n# AWAvenue-Ads-Rule End/' >> /etc/hosts" >> "$TARGET_FILE"
                echo "sed -i '/^$/d' /etc/hosts" >> "$TARGET_FILE"
                echo "sed -i '/!/d' /etc/hosts" >> "$TARGET_FILE"
                echo "# 广告过滤规则拉取脚本结束" >> "$TARGET_FILE"
                echo "已添加 秋风广告过滤规则！"
                break
                ;;
            *)
                echo "无效选项，请重新输入。"
                ;;
        esac
    done

    # 询问是否添加 GitHub520 加速规则
    while true; do
        read -p "是否添加 GitHub520 加速规则？(Y/N，默认Y) " ADD_GITHUB
        ADD_GITHUB=${ADD_GITHUB:-Y}  # 默认为 Y
        case "$ADD_GITHUB" in
            [Yy])
                # 添加 GitHub520 加速规则
                echo "# 以下是 GitHub520 加速规则拉取脚本" >> "$TARGET_FILE"
                echo "LOG_OUT \"拉取 GitHub520 加速规则…\"" >> "$TARGET_FILE"
                echo "sed -i '/# GitHub520 Host Start/,/# GitHub520 Host End/d' /etc/hosts" >> "$TARGET_FILE"
                echo "curl https://raw.hellogithub.com/hosts >> /etc/hosts" >> "$TARGET_FILE"
                echo "sed -i '/^$/d' /etc/hosts" >> "$TARGET_FILE"
                echo "sed -i '/!/d' /etc/hosts" >> "$TARGET_FILE"
                echo "# GitHub520 加速规则拉取脚本结束" >> "$TARGET_FILE"
                echo "已添加 GitHub520 加速规则"
                break
                ;;
            [Nn])
                # 用户选择不添加 GitHub520 加速规则
                break
                ;;
            *)
                echo "无效输入，请重新输入。"
                ;;
        esac
    done

    # 在文件末尾添加空行
    echo "" >> "$TARGET_FILE"

    # 添加 exit 0 前延迟 5 秒
    echo "sleep 5" >> "$TARGET_FILE"
    echo "exit 0" >> "$TARGET_FILE"

    # 提示用户所有规则将在 OpenClash 下次启动时生效
    echo "所有规则将在 OpenClash 下次启动时生效，脚本退出。"
}

# 调用主函数
main
