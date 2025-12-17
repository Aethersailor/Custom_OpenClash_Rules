#!/bin/sh

# 定义颜色
R='\033[1;31m' # Red
G='\033[1;32m' # Green
Y='\033[1;33m' # Yellow
B='\033[1;34m' # Blue
C='\033[1;36m' # Cyan
W='\033[1;37m' # White
N='\033[0m'    # No Color

# 定义符号
INFO="${B}[INFO]${N}"
WARN="${Y}[WARN]${N}"
ERR="${R}[ERROR]${N}"
OK="${G}[OK]${N}"

# 打印分界线函数
print_line() {
    echo -e "${C}================================================================${N}"
}

# 打印步骤标题函数
print_step() {
    echo
    print_line
    echo -e "${W}>> $1${N}"
    print_line
}

# 打印欢迎信息
logo() {
    clear
    echo -e "${C}################################################################${N}"
    echo -e "${C}#                                                              #${N}"
    echo -e "${C}#              Custom_OpenClash_Rules Auto Installer           #${N}"
    echo -e "${C}#     https://github.com/Aethersailor/Custom_OpenClash_Rules   #${N}"
    echo -e "${C}#                                                              #${N}"
    echo -e "${C}################################################################${N}"
    echo -e "${W}* OpenClash Dev 在线全自动化安装脚本${N}"
    echo
    sleep 1
}

# 定义变量
REPO_API_URL="https://api.github.com/repos/vernesong/OpenClash/contents/dev?ref=package"
RAW_FILE_PREFIX="https://testingcf.jsdelivr.net/gh/vernesong/OpenClash@refs/heads/package/dev"

logo
echo -e "${INFO} 开始运行..."
echo -e "${INFO} 即将安装/升级插件至最新 dev 版本。"
sleep 1

# 1. 检查包管理器
print_step "步骤 1/4: 检查系统包管理器"
if command -v opkg >/dev/null 2>&1; then
    PKG_MGR="opkg"
    EXT="ipk"
    INSTALL_CMD="opkg install --force-reinstall"
    echo -e "$OK 检测到包管理器：${G}OPKG (OpenWrt)${N}"
elif command -v apk >/dev/null 2>&1; then
    PKG_MGR="apk"
    EXT="apk"
    INSTALL_CMD="apk add -q --force-overwrite --clean-protected --allow-untrusted"
    echo -e "$OK 检测到包管理器：${G}APK (OpenWrt Snapshot)${N}"
else
    echo -e "$ERR 未检测到支持的包管理器 (opkg/apk)"
    echo -e "$INFO 请确保在支持的系统上运行此脚本。"
    exit 1
fi

# 2. 下载并安装 OpenClash
print_step "步骤 2/4: 下载并安装 OpenClash Dev"
echo -e "$INFO 正在获取版本信息..."
JSON_OUTPUT=$(wget -qO- "$REPO_API_URL")
FILE_NAME=$(echo "$JSON_OUTPUT" \
    | grep -oE '"name":\s*"[^\"]+\.'"$EXT"'"' \
    | sed -E 's/.*"([^\"]+)".*/\1/' \
    | head -n 1)

if [ -z "$FILE_NAME" ]; then
    echo -e "$ERR 未在官方仓库找到 .$EXT 文件，请检查网络。"
    exit 1
fi

echo -e "$INFO 发现最新版本：${G}$FILE_NAME${N}"
DOWNLOAD_URL="$RAW_FILE_PREFIX/$FILE_NAME"
TEMP_FILE="openclash.$EXT"
echo

echo -e "$INFO 开始下载..."
wget --show-progress --progress=bar:force:noscroll -O "$TEMP_FILE" "$DOWNLOAD_URL" 2>/dev/null || wget -O "$TEMP_FILE" "$DOWNLOAD_URL"

if [ $? -ne 0 ]; then
    echo -e "$ERR 下载失败。"
    exit 1
fi
echo -e "$OK 下载完成。"
echo

echo -e "$INFO 正在安装..."
$INSTALL_CMD "$TEMP_FILE"
RET=$?
rm -f "$TEMP_FILE"

if [ $RET -ne 0 ]; then
    echo -e "$ERR 安装失败，请检查系统环境。"
    exit 1
fi
echo
echo -e "$OK OpenClash Dev 安装成功！"

# 3. 配置 OpenClash
print_step "步骤 3/4: 初始化配置"
echo -e "$INFO 配置更新分支为 Dev，启用 jsdelivr 加速..."
uci set openclash.config.release_branch=dev
uci set openclash.config.skip_safe_path_check=1
uci set openclash.config.github_address_mod='https://testingcf.jsdelivr.net/'
uci commit openclash
echo -e "$OK 基础配置更新完成。"
echo

echo -e "$INFO 正在调用内部脚本更新内核..."
/usr/share/openclash/openclash_core.sh
if [ $? -ne 0 ]; then
  echo -e "$ERR Meta 内核更新失败，请检查日志。"
  exit 1
fi
echo -e "$OK Meta 内核更新完成！"

# 4. 启动
print_step "步骤 4/4: 启动服务"
echo -e "$INFO 设置开机自启并启动 OpenClash..."
uci set openclash.config.enable='1'
uci commit openclash
/etc/init.d/openclash restart >/dev/null 2>&1
echo -e "$OK OpenClash 启动指令已发送。"

echo
print_line
echo -e "${G}[OK] 脚本运行完毕！${N}"
echo
