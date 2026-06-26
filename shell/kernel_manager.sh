#!/bin/bash

# =================================================================
# 脚本名称: kernel_manager.sh
# 描述: Debian 系统内核管理助手 (支持管道运行)
# 功能: 自动对比内核版本、引导重启、深度清理旧内核及其残留
# 作者: Aethersailor
# =================================================================

# 检查 root 权限
if [ "$EUID" -ne 0 ]; then
  echo -e "\e[31m请使用 root 权限运行此脚本 (sudo)！\e[0m"
  exit 1
fi

# 定义颜色
GREEN='\e[32m'
YELLOW='\e[33m'
RED='\e[31m'
BLUE='\e[34m'
NC='\e[0m'

echo -e "${BLUE}--- Debian 内核深度管理助手 (支持管道运行版) ---${NC}"

# 1. 获取当前系统信息
RUNNING_KERNEL=$(uname -r)
# 获取所有状态为 ii (已安装) 的内核镜像包名
INSTALLED_IMAGE_PKGS=$(dpkg --list | grep '^ii  linux-image-[0-9]' | awk '{print $2}')

# 提取版本号列表并排序
VERSION_LIST=$(echo "$INSTALLED_IMAGE_PKGS" | sed 's/linux-image-//' | sort -V)
LATEST_INSTALLED=$(echo "$VERSION_LIST" | tail -n 1)

echo -e "当前运行内核: ${GREEN}$RUNNING_KERNEL${NC}"
echo -e "系统最新内核: ${GREEN}$LATEST_INSTALLED${NC}"

# 2. 状态判断：是否需要重启切换到新内核
if dpkg --compare-versions "$RUNNING_KERNEL" lt "$LATEST_INSTALLED"; then
    echo -e "\n${YELLOW}[提示] 当前运行的不是最新内核，新内核需重启后生效。${NC}"
    # 注意: < /dev/tty 解决了管道运行时无法读取键盘输入的问题
    read -p "是否立即重启以切换到新内核 ($LATEST_INSTALLED)？[y/N]: " REBOOT_CONFIRM < /dev/tty
    if [[ "$REBOOT_CONFIRM" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}正在重启系统...${NC}"
        reboot
    else
        echo -e "已取消重启。请择日手动重启以完成更新。"
        exit 0
    fi
fi

# 安全检查：防止意外删除了正在使用的内核
if [ "$RUNNING_KERNEL" != "$LATEST_INSTALLED" ]; then
    echo -e "${RED}[警告] 当前运行的内核版本异常，脚本停止操作以防止系统损坏。${NC}"
    exit 1
fi

# 3. 识别并列出旧内核
OLD_VERSIONS=$(echo "$VERSION_LIST" | grep -v "$RUNNING_KERNEL")

if [ -z "$OLD_VERSIONS" ]; then
    echo -e "${BLUE}没有发现旧版本内核，系统环境很干净。${NC}"
    exit 0
fi

echo -e "\n${YELLOW}发现以下旧内核版本及其关联组件：${NC}"
for VER in $OLD_VERSIONS; do
    # 动态搜索所有包含该版本号的已安装包
    RELATED_PKGS=$(dpkg --list | grep "^ii" | grep "$VER" | awk '{print $2}')
    echo -e "${BLUE}版本 [$VER] 相关包：${NC}"
    echo "$RELATED_PKGS" | sed 's/^/  - /'
done

# 4. 用户确认清理
read -p "是否确认【深度彻底清理】以上所有包及残留文件？[y/N]: " PURGE_CONFIRM < /dev/tty
if [[ ! "$PURGE_CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}操作已取消。${NC}"
    exit 0
fi

# 5. 执行彻底清理流程
for VER in $OLD_VERSIONS; do
    echo -e "\n${RED}正在处理版本: $VER${NC}"

    # A. 卸载所有关联软件包
    RELATED_PKGS=$(dpkg --list | grep "^ii" | grep "$VER" | awk '{print $2}')
    if [ -n "$RELATED_PKGS" ]; then
        echo -e "Step 1: 正在 Purge 软件包..."
        apt-get purge -y $RELATED_PKGS
    fi

    # B. 强制物理清理 (解决目录非空和 /boot 残留问题)
    echo -e "Step 2: 正在强制清理物理文件残留..."
    # 清理模块目录
    if [ -d "/lib/modules/$VER" ]; then
        rm -rf "/lib/modules/$VER"
    fi
    # 清理 /boot 目录下所有包含该版本号的文件
    rm -f /boot/*"$VER"*
done

# C. 自动清理孤儿依赖
echo -e "\n${BLUE}Step 3: 正在执行 autoremove 清理冗余依赖...${NC}"
apt-get autoremove --purge -y

# D. 刷新引导配置
echo -e "\n${BLUE}Step 4: 正在更新 GRUB 引导菜单...${NC}"
update-grub

# 6. 结果展示
echo -e "\n${GREEN}--- 清理任务圆满完成 ---${NC}"
echo -e "当前 /boot 目录状态："
ls -lh /boot | grep -E "vmlinuz|initrd"

echo -e "\n当前 GRUB 菜单有效引导项："
grep -i "menuentry" /boot/grub/grub.cfg | grep "Linux" | cut -d "'" -f 2 | sed 's/^/  /'
