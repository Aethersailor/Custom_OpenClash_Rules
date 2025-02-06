#!/bin/sh
. /usr/share/openclash/log.sh
. /lib/functions.sh

# This script is called by /etc/init.d/openclash
# Add your custom firewall rules here, they will be added after the end of the OpenClash iptables rules

LOG_OUT "Tip: Start Add Custom Firewall Rules..."

# ==============以下是广告过滤规则拉取脚本=================
# 在后台子进程中执行规则拉取任务
(
    # 设置最大等待时间（秒）
    MAX_WAIT_TIME=30
    # 设置等待间隔（秒）
    WAIT_INTERVAL=2
    # 初始化已等待时间
    elapsed_time=0

    # 循环检测 OpenClash 是否正在运行
    while ! /etc/init.d/openclash status | grep -q "running"; do
        if [ $elapsed_time -ge $MAX_WAIT_TIME ]; then
            LOG_OUT "[广告过滤规则拉取脚本]未能在 30 秒内检测到 OpenClash 运行状态，脚本已停止运行..."
            exit 1
        fi
        LOG_OUT "[广告过滤规则拉取脚本]正在检查 OpenClash 运行状态，请稍后..."
        sleep $WAIT_INTERVAL
        elapsed_time=$((elapsed_time + WAIT_INTERVAL))
    done

    LOG_OUT "[广告过滤规则拉取脚本]检测到 OpenClash 正在运行，5秒后开始拉取规则..."
    sleep 5
    # 删除已存在的 anti-AD 规则文件
    LOG_OUT "清除已有的 anti-AD 广告过滤规则…"
    rm -f /tmp/dnsmasq.d/anti-ad-for-dnsmasq.conf
    rm -f /tmp/dnsmasq.cfg01411c.d/anti-ad-for-dnsmasq.conf

    LOG_OUT "拉取最新 anti-AD 广告过滤规则…"
    # 下载 anti-AD 规则，设置最大执行时间为 10 秒
    curl -sk  "https://anti-ad.net/anti-ad-for-dnsmasq.conf" -o /tmp/dnsmasq.cfg01411c.d/anti-ad-for-dnsmasq.conf > /tmp/anti-ad-curl.log 2>&1

    # 检查 curl 命令是否成功
    if [ $? -eq 0 ]; then
        LOG_OUT "anti-AD 规则拉取成功！"
    else
        LOG_OUT "anti-AD 规则拉取失败，查看 /tmp/anti-ad-curl.log 获取详细信息。"
    fi

    # GitHub520 加速规则拉取脚本
    # 删除旧的 GitHub520 规则
    LOG_OUT "清除已有的 GitHub520 加速规则…"
    sed -i '/# GitHub520 Host Start/,/# GitHub520 Host End/d' /etc/hosts

    LOG_OUT "拉取最新的 GitHub520 加速规则…"
    # 下载 GitHub520 规则并追加到 /etc/hosts，设置最大执行时间为 10 秒
    curl -sk "https://raw.hellogithub.com/hosts" >> /etc/hosts > /tmp/github520-curl.log 2>&1

    # 检查 curl 命令是否成功
    if [ $? -eq 0 ]; then
        LOG_OUT "GitHub520 加速规则拉取成功！"
    else
        LOG_OUT "GitHub520 加速规则拉取失败，查看 /tmp/github520-curl.log 获取详细信息。"
    fi

    # 清理 /etc/hosts 中空行和注释行
    sed -i '/^$/d' /etc/hosts
    sed -i '/!/d' /etc/hosts

    # 清理 DNS 缓存
    LOG_OUT "清理 DNS 缓存…"
    /etc/init.d/dnsmasq reload
    LOG_OUT "[广告过滤规则拉取脚本]执行完毕！"

) &
# ==============广告过滤规则拉取脚本结束==============


exit 0