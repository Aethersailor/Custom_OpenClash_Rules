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
    echo -e "${W}* OpenClash Dev 在线全自动化安装与更新脚本${N}"
    echo
    sleep 1
}

# 定义变量
REPO_API_URL="https://api.github.com/repos/vernesong/OpenClash/contents/dev?ref=package"
RAW_FILE_PREFIX="https://testingcf.jsdelivr.net/gh/vernesong/OpenClash@refs/heads/package/dev"

logo
echo -e "${INFO} 开始运行..."
echo -e "${INFO} 即将安装/升级插件至最新 dev 版本，并更新所有配套资源。"
sleep 1

# 1. 检查包管理器
print_step "步骤 1/8: 检查系统包管理器"
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

# 2. 检查防火墙架构
print_step "步骤 2/8: 检查防火墙架构"
FIREWALL_TYPE=""
if command -v fw4 >/dev/null 2>&1; then
    echo -e "$OK 检测到防火墙：${G}fw4 (nftables)${N}"
    FIREWALL_TYPE="nftables"
elif command -v fw3 >/dev/null 2>&1; then
    echo -e "$OK 检测到防火墙：${G}fw3 (iptables)${N}"
    FIREWALL_TYPE="iptables"
else
    if command -v nft >/dev/null 2>&1; then
       echo -e "$OK 检测到防火墙：${G}nftables${N}"
       FIREWALL_TYPE="nftables"
    elif command -v iptables >/dev/null 2>&1; then
       echo -e "$OK 检测到防火墙：${G}iptables${N}"
       FIREWALL_TYPE="iptables"
    else
       echo -e "$WARN 未检测到已知防火墙架构"
    fi
fi

# 3. 安装依赖
print_step "步骤 3/8: 检查并安装依赖 [${FIREWALL_TYPE:-Null}]"

if [ -n "$FIREWALL_TYPE" ]; then
    if [ "$FIREWALL_TYPE" = "nftables" ]; then
        DEPENDENCIES="bash dnsmasq-full curl ca-bundle ip-full ruby ruby-yaml kmod-tun kmod-inet-diag unzip kmod-nft-tproxy luci-compat luci luci-base"
    else
        DEPENDENCIES="bash iptables dnsmasq-full curl ca-bundle ipset ip-full iptables-mod-tproxy iptables-mod-extra ruby ruby-yaml kmod-tun kmod-inet-diag unzip luci-compat luci luci-base"
    fi

    echo -e "$INFO 正在准备 ${G}$FIREWALL_TYPE${N} 环境运行 OpenClash 所需的依赖..."
    echo -e "$INFO 目标依赖列表: ${W}$DEPENDENCIES${N}"
    echo

    if [ "$PKG_MGR" = "opkg" ]; then
        opkg install $DEPENDENCIES
    elif [ "$PKG_MGR" = "apk" ]; then
        apk add $DEPENDENCIES
    fi
    echo
    echo -e "$OK 依赖安装检查完成。"
else
    echo -e "$WARN 由于未检测到已知防火墙架构，跳过依赖安装步骤。"
    echo -e "$INFO 请自行确保系统已安装 OpenClash 所需的依赖。"
fi

# 4. 下载并安装 OpenClash
print_step "步骤 4/8: 下载并安装 OpenClash Dev"
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

# 5. 加载个性化配置
print_step "步骤 5/8: 加载个性化配置"
if [ -f /etc/config/openclash-set ]; then
  echo -e "$INFO 检测到预设文件 ${W}/etc/config/openclash-set${N}"
  echo -e "$INFO 正在执行..."
  echo
  sh /etc/config/openclash-set
  if [ $? -ne 0 ]; then
    echo -e "$ERR 加载个性化配置出错。"
    exit 1
  fi
  echo
  echo -e "$OK 个性化配置加载完成。"
else
  echo -e "$INFO 未检测到预设文件，跳过。"
fi

# 6. 配置 OpenClash
print_step "步骤 6/8: 初始化配置与内核更新"
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
  echo -e "$ERR 内核更新失败，请检查日志。"
  exit 1
fi
echo -e "$OK 内核更新完成。"
echo

# Smart 内核逻辑
CORE_TYPE=$(uci get openclash.config.core_type 2>/dev/null)
if [ "$CORE_TYPE" = "Smart" ]; then
  echo -e "$INFO 检测到 Smart 内核模式，正在配置..."
  uci set openclash.config.auto_smart_switch='1'
  uci set openclash.config.lgbm_auto_update='1'
  uci set openclash.config.lgbm_custom_url='https://github.com/vernesong/mihomo/releases/download/LightGBM-Model/Model-large.bin'
  uci commit openclash

  echo
  echo -e "$INFO 准备更新 Smart 模型 (Model-large.bin)..."
  TMP_MODEL="/tmp/Model-large.bin"
  TARGET_DIR="/etc/openclash"
  TARGET_FILE="$TARGET_DIR/Model.bin"
  MODEL_URL="https://gh-proxy.com/https://github.com/vernesong/mihomo/releases/download/LightGBM-Model/Model-large.bin"
  DOMAIN="gh-proxy.com"

  mkdir -p "$TARGET_DIR"
  
  if ! command -v curl >/dev/null 2>&1; then
      echo -e "$ERR 未找到 curl。"
      exit 1
  fi

  echo -e "$INFO 使用阿里云 DoH 解析 ${W}$DOMAIN${N}..."
  RESOLVED_IP=$(curl -s "https://223.5.5.5/resolve?name=$DOMAIN&type=A" | grep -oE '"data":"[0-9]{1,3}(\.[0-9]{1,3}){3}"' | cut -d'"' -f4 | head -n 1)
  
  if [ -z "$RESOLVED_IP" ]; then
      RESOLVED_IP=$(curl -s "https://223.6.6.6/resolve?name=$DOMAIN&type=A" | grep -oE '"data":"[0-9]{1,3}(\.[0-9]{1,3}){3}"' | cut -d'"' -f4 | head -n 1)
  fi

  CURL_ARGS="-L --fail --retry 3 --connect-timeout 30 --max-time 600 --insecure"
  
  if [ -n "$RESOLVED_IP" ]; then
      echo -e "$OK DoH 解析成功: ${G}$RESOLVED_IP${N}"
      CURL_ARGS="$CURL_ARGS --resolve $DOMAIN:443:$RESOLVED_IP"
  else
      echo -e "$WARN DoH 解析失败，将使用系统 DNS..."
  fi

  echo -e "$INFO 开始下载模型..."
  curl $CURL_ARGS -o "$TMP_MODEL" "$MODEL_URL"
  
  if [ $? -eq 0 ] && [ -s "$TMP_MODEL" ]; then
    echo -e "$OK 下载成功。"
    mv -f "$TMP_MODEL" "$TARGET_FILE"
    chmod 644 "$TARGET_FILE"
  else
    echo -e "$ERR 下载失败。"
    [ -f "$TMP_MODEL" ] && rm -f "$TMP_MODEL"
    exit 1
  fi
  echo -e "$OK Smart 模型更新完成。"
else
  echo -e "$INFO Smart 内核未开启，跳过模型更新。"
fi

# 7. 更新数据库与规则
print_step "步骤 7/8: 更新数据库与规则资源"

update_res() {
    NAME=$1
    SCRIPT=$2
    echo -e "$INFO 正在更新 $NAME..."
    $SCRIPT
    if [ $? -eq 0 ]; then
        echo -e "$OK $NAME 更新完成。"
        echo
    else
        echo -e "$ERR $NAME 更新失败。"
        exit 1
    fi
}

update_res "GeoIP Dat 数据库" "/usr/share/openclash/openclash_geoip.sh"
update_res "GeoIP MMDB 数据库" "/usr/share/openclash/openclash_ipdb.sh"
update_res "GeoSite 数据库" "/usr/share/openclash/openclash_geosite.sh"
update_res "GeoASN 数据库" "/usr/share/openclash/openclash_geoasn.sh"
update_res "大陆 IP 白名单" "/usr/share/openclash/openclash_chnroute.sh"

echo -e "$INFO 正在更新订阅..."
/usr/share/openclash/openclash.sh
if [ $? -ne 0 ]; then
    echo -e "$ERR 订阅更新失败，请检查日志。"
    exit 1
fi
echo -e "$OK 订阅更新完成。"

# 8. 启动
print_step "步骤 8/8: 启动服务"
echo -e "$INFO 设置开机自启并启动 OpenClash..."
uci set openclash.config.enable='1'
uci commit openclash
/etc/init.d/openclash restart >/dev/null 2>&1
echo -e "$OK OpenClash 启动指令已发送。"

echo
print_line
echo -e "${G}[OK] 脚本运行完毕！${N}"
echo
