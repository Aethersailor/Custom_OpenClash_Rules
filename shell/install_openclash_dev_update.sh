#!/bin/sh
# ================================================================
# Custom_OpenClash_Rules 自动安装脚本
# 项目地址: https://github.com/Aethersailor/Custom_OpenClash_Rules
# 功能: 自动安装/更新 OpenClash Dev 版本及全套配置
# ================================================================

# ================================================================
# 颜色定义
# ================================================================
R='\033[1;31m' # 红色
G='\033[1;32m' # 绿色
Y='\033[1;33m' # 黄色
B='\033[1;34m' # 蓝色
C='\033[1;36m' # 青色
W='\033[1;37m' # 白色
N='\033[0m'    # 重置

# ================================================================
# 提示符号定义（使用 ASCII 符号，确保对齐）
# ================================================================
INFO="${B}[i]${N}"
WARN="${Y}[!]${N}"
ERR="${R}[✗]${N}"
OK="${G}[✓]${N}"
ARROW="${C}  →${N}"  # 子步骤箭头

# ================================================================
# 工具函数定义
# ================================================================

# 函数: 打印分界线
print_line() {
    echo -e "${C}================================================================${N}"
}

# 函数: 打印步骤标题
print_step() {
    echo
    print_line
    echo -e "${W}>> $1${N}"
    print_line
}

# 函数: 打印欢迎信息
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

# ================================================================
# 全局变量定义
# ================================================================
REPO_API_URL="https://api.github.com/repos/vernesong/OpenClash/contents/dev?ref=package"
RAW_FILE_PREFIX="https://testingcf.jsdelivr.net/gh/vernesong/OpenClash@refs/heads/package/dev"

logo
echo -e "${INFO} 开始运行..."
echo -e "${INFO} 即将安装/升级插件至最新 dev 版本，并更新所有配套资源。"
sleep 1

# 1. 系统环境检测（合并包管理器、防火墙、OpenClash 状态检查）
print_step "步骤 1/8: 系统环境检测"
echo

# 检测包管理器
PKG_MGR=""
EXT=""
INSTALL_CMD=""

if command -v opkg >/dev/null 2>&1; then
    PKG_MGR="opkg"
    EXT="ipk"
    INSTALL_CMD="opkg install --force-reinstall"
    echo -e "$OK 包管理器: ${G}OPKG (OpenWrt)${N}"
elif command -v apk >/dev/null 2>&1; then
    PKG_MGR="apk"
    EXT="apk"
    INSTALL_CMD="apk add -q --force-overwrite --clean-protected --allow-untrusted"
    echo -e "$OK 包管理器: ${G}APK (Snapshot)${N}"
else
    echo -e "$ERR 包管理器: ${R}未检测到${N}"
fi

# 检测防火墙架构
FIREWALL_TYPE=""

if command -v fw4 >/dev/null 2>&1; then
    FIREWALL_TYPE="nftables"
    echo -e "$OK 防火墙: ${G}fw4 (nftables)${N}"
elif command -v fw3 >/dev/null 2>&1; then
    FIREWALL_TYPE="iptables"
    echo -e "$OK 防火墙: ${G}fw3 (iptables)${N}"
elif command -v nft >/dev/null 2>&1; then
    FIREWALL_TYPE="nftables"
    echo -e "$OK 防火墙: ${G}nftables${N}"
elif command -v iptables >/dev/null 2>&1; then
    FIREWALL_TYPE="iptables"
    echo -e "$OK 防火墙: ${G}iptables${N}"
else
    echo -e "$WARN 防火墙: ${Y}未检测到${N}"
fi

# 检测 OpenClash 安装状态
OPENCLASH_VERSION=""

if [ "$PKG_MGR" = "opkg" ]; then
    OPENCLASH_VERSION=$(opkg list-installed luci-app-openclash 2>/dev/null | awk '{print $3}')
elif [ "$PKG_MGR" = "apk" ]; then
    OPENCLASH_VERSION=$(apk list -I 2>/dev/null | grep "^luci-app-openclash-" | sed -E 's/^luci-app-openclash-([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
fi

if [ -n "$OPENCLASH_VERSION" ]; then
    echo -e "$OK OpenClash: ${G}已安装 v$OPENCLASH_VERSION${N}"
else
    echo -e "$INFO OpenClash: ${W}未安装${N}"
fi

echo

# 检查包管理器是否可用
if [ -z "$PKG_MGR" ]; then
    echo -e "$ERR 未检测到支持的包管理器 (opkg/apk)"
    echo -e "$INFO 请确保在支持的系统上运行此脚本。"
    exit 1
fi

echo -e "$OK 系统环境检测完成"
sleep 1

# 4. 安装依赖
print_step "步骤 2/8: 检查并安装依赖 [${FIREWALL_TYPE:-Null}]"

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
sleep 1

# ================================================================
# 步骤 3: 获取 GitHub Hosts 信息
# ================================================================
# GitHub Hosts 相关变量
GITHUB_HOSTS_URL="https://raw.hellogithub.com/hosts"
GITHUB_HOSTS_CACHE="/tmp/github_hosts_cache.txt"
API_GITHUB_IP=""
GITHUB_COM_IP=""

# 函数: 获取 GitHub Hosts 文件
# 功能: 从 hellogithub.com 获取 GitHub 域名的 IP 映射以应对 DNS 污染
get_github_hosts() {
    echo -e "$INFO 正在获取 GitHub 域名解析信息以应对 DNS 污染..."
    
    # 使用 curl 下载 hosts 文件到缓存（依赖安装后 curl 已可用）
    if curl -sL -m 10 -o "$GITHUB_HOSTS_CACHE" "$GITHUB_HOSTS_URL" 2>/dev/null && [ -s "$GITHUB_HOSTS_CACHE" ]; then
        echo -e "$OK GitHub Hosts 信息获取成功。"
        
        # 解析 api.github.com 的 IP
        API_GITHUB_IP=$(grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+api\.github\.com' "$GITHUB_HOSTS_CACHE" | awk '{print $1}' | head -n 1)
        
        # 解析 github.com 的 IP
        GITHUB_COM_IP=$(grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+github\.com' "$GITHUB_HOSTS_CACHE" | awk '{print $1}' | head -n 1)
        
        if [ -n "$API_GITHUB_IP" ]; then
            echo -e "$OK 解析到 api.github.com: ${G}${API_GITHUB_IP}${N}"
        fi
        
        if [ -n "$GITHUB_COM_IP" ]; then
            echo -e "$OK 解析到 github.com: ${G}${GITHUB_COM_IP}${N}"
        fi
        
        return 0
    else
        echo -e "$WARN 无法获取 GitHub Hosts 信息，将使用默认 DNS 解析。"
        return 1
    fi
}

print_step "步骤 3/8: 获取 GitHub Hosts 信息"
get_github_hosts
sleep 1

# ================================================================
# 步骤 4: 下载并安装 OpenClash Dev
# ================================================================
print_step "步骤 4/8: 下载并安装 OpenClash Dev"

echo -e "$INFO 正在获取版本信息..."

JSON_OUTPUT=""

# 如果解析到了 api.github.com 的 IP，优先使用 curl --resolve 强制域名解析
if [ -n "$API_GITHUB_IP" ]; then
    echo -e "$INFO 使用解析的 IP (${G}${API_GITHUB_IP}${N}) 访问 GitHub API..."
    JSON_OUTPUT=$(curl -sL --connect-timeout 10 --resolve "api.github.com:443:${API_GITHUB_IP}" "$REPO_API_URL" 2>/dev/null)
    
    # 检查是否成功获取到数据
    if [ -z "$JSON_OUTPUT" ] || ! echo "$JSON_OUTPUT" | grep -q "\"name\""; then
        echo -e "$WARN IP 访问失败，尝试使用反代访问..."
        PROXY_API_URL="https://github-proxy.asailor.org/${REPO_API_URL}"
        JSON_OUTPUT=$(curl -sL --connect-timeout 10 "$PROXY_API_URL" 2>/dev/null)
    fi
else
    # 没有获取到 IP，直接使用反代
    echo -e "$INFO 使用反代访问 GitHub API..."
    PROXY_API_URL="https://github-proxy.asailor.org/${REPO_API_URL}"
    JSON_OUTPUT=$(curl -sL --connect-timeout 10 "$PROXY_API_URL" 2>/dev/null)
fi
FILE_NAME=$(echo "$JSON_OUTPUT" \
    | grep -oE '"name":\s*"[^\"]+\.'"$EXT"'"' \
    | sed -E 's/.*"([^\"]+)".*/\1/' \
    | head -n 1)

if [ -z "$FILE_NAME" ]; then
    echo -e "$ERR 未在官方仓库找到 .$EXT 文件，请检查网络。"
    exit 1
fi

echo -e "$INFO 发现最新版本：${G}$FILE_NAME${N}"
JSDELIVR_URL="$RAW_FILE_PREFIX/$FILE_NAME"
GITHUB_RAW_URL="https://raw.githubusercontent.com/vernesong/OpenClash/package/dev/$FILE_NAME"
PROXY_URL="https://github-proxy.asailor.org/${GITHUB_RAW_URL}"
TEMP_FILE="openclash.$EXT"
echo

DOWNLOAD_SUCCESS=0

# 下载 OpenClash 安装包（优先级: jsDelivr CDN > GitHub IP > 反代）
echo -e "$INFO 开始使用 jsDelivr CDN 下载..."

curl -C - -sL --fail --retry 3 --retry-delay 2 --connect-timeout 30 --max-time 600 -o "$TEMP_FILE" "$JSDELIVR_URL"

if [ $? -eq 0 ] && [ -s "$TEMP_FILE" ]; then
  DOWNLOAD_SUCCESS=1
else
  echo -e "$WARN jsDelivr CDN 下载失败。"
fi

# 尝试使用 GitHub 原始地址（配合 IP）
if [ $DOWNLOAD_SUCCESS -eq 0 ] && [ -n "$GITHUB_COM_IP" ]; then
  echo -e "$INFO 尝试使用 GitHub 原始地址下载 (通过解析的 IP)..."
  
  curl -C - -sL --fail --retry 3 --retry-delay 2 --connect-timeout 30 --max-time 600 \
    --resolve "raw.githubusercontent.com:443:${GITHUB_COM_IP}" \
    -o "$TEMP_FILE" "$GITHUB_RAW_URL"
  
  if [ $? -eq 0 ] && [ -s "$TEMP_FILE" ]; then
    DOWNLOAD_SUCCESS=1
  else
    echo -e "$WARN GitHub 原始地址下载失败。"
  fi
fi

# 尝试使用反代
if [ $DOWNLOAD_SUCCESS -eq 0 ]; then
  echo -e "$INFO 尝试使用反代下载..."
  
  curl -C - -sL --fail --retry 3 --retry-delay 2 --connect-timeout 30 --max-time 600 -o "$TEMP_FILE" "$PROXY_URL"
  
  if [ $? -eq 0 ] && [ -s "$TEMP_FILE" ]; then
    DOWNLOAD_SUCCESS=1
  fi
fi

echo

if [ $DOWNLOAD_SUCCESS -eq 0 ]; then
    echo -e "$ERR 下载失败（jsDelivr CDN、GitHub 原始地址和反代均失败）。"
    exit 1
fi
echo -e "$OK OpenClash 安装包下载成功。"

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
sleep 1

# ================================================================  
# 步骤 5: 检查并配置 core_version
# ================================================================
print_step "步骤 5/8: 检查并配置 core_version"
CORE_VERSION=$(uci get openclash.config.core_version 2>/dev/null)

# 检查是否需要重新检测架构
NEED_DETECT=0
if [ -z "$CORE_VERSION" ]; then
    echo -e "$INFO core_version 未配置，正在检测 CPU 架构..."
    NEED_DETECT=1
elif echo "$CORE_VERSION" | grep -qE '^linux-amd64'; then
    echo -e "$INFO 检测到 x86 架构配置：${G}$CORE_VERSION${N}"
    echo -e "$INFO 正在重新检测以确保使用最优微架构版本..."
    NEED_DETECT=1
else
    echo -e "$OK core_version 已配置：${G}$CORE_VERSION${N}"
fi

if [ $NEED_DETECT -eq 1 ]; then
    # 检测 MIPS 浮点类型
    detect_mips_float() {
        if grep -q "FPU.*yes" /proc/cpuinfo 2>/dev/null; then
            echo "hardfloat"
        else
            echo "softfloat"
        fi
    }
    
    # 检测 LoongArch ABI 版本
    detect_loongarch_abi() {
        kernel_ver=$(uname -r | cut -d. -f1,2)
        major=$(echo "$kernel_ver" | cut -d. -f1)
        minor=$(echo "$kernel_ver" | cut -d. -f2)
        
        if [ "$major" -gt 5 ] || ([ "$major" -eq 5 ] && [ "$minor" -ge 19 ]); then
            echo "abi2"
        else
            echo "abi1"
        fi
    }
    
    # 架构名称映射函数
    map_arch() {
        local arch="$1"
        local result=""
        
        case "$arch" in
            x86_64)
                result="amd64"
                ;;
            i386|i686)
                result="386"
                ;;
            aarch64|arm64)
                result="arm64"
                ;;
            armv7l|armv7)
                result="armv7"
                ;;
            armv6l|armv6)
                result="armv6"
                ;;
            armv5tel|armv5)
                result="armv5"
                ;;
            mips64)
                result="mips64"
                ;;
            mips64el)
                result="mips64le"
                ;;
            mips)
                result="mips-$(detect_mips_float)"
                ;;
            mipsel)
                result="mipsle-$(detect_mips_float)"
                ;;
            loongarch64)
                result="loong64-$(detect_loongarch_abi)"
                ;;
            riscv64)
                result="riscv64"
                ;;
            s390x)
                result="s390x"
                ;;
            *)
                result="$arch"
                ;;
        esac
        
        echo "linux-$result"
    }
    
    # 判断 CPU 架构
    arch=$(uname -m)
    if [ "$arch" != "x86_64" ]; then
        DETECTED_ARCH=$(map_arch "$arch")
    else
        # x86_64 架构，读取 CPU flags
        flags=$(grep -m1 -o -E 'flags\s*:.*' /proc/cpuinfo | cut -d: -f2)
        
        # 判断 v4 (AVX512)
        if echo "$flags" | grep -qE 'avx512f'; then
            DETECTED_ARCH="linux-amd64-v4"
        # 判断 v3 (AVX/AVX2 等)
        elif echo "$flags" | grep -qE 'avx' && \
             echo "$flags" | grep -qE 'avx2' && \
             echo "$flags" | grep -qE 'bmi1' && \
             echo "$flags" | grep -qE 'bmi2'; then
            DETECTED_ARCH="linux-amd64-v3"
        # 判断 v2 (SSE4.2 / SSE3 / POPCNT 等)
        elif echo "$flags" | grep -qE 'sse4_2' && \
             echo "$flags" | grep -qE 'sse4_1' && \
             echo "$flags" | grep -qE 'ssse3' && \
             echo "$flags" | grep -qE 'sse3' && \
             echo "$flags" | grep -qE 'popcnt'; then
            DETECTED_ARCH="linux-amd64-v2"
        else
            DETECTED_ARCH="linux-amd64-v1"
        fi
    fi
    
    echo -e "$OK 检测到 CPU 架构：${G}$DETECTED_ARCH${N}"
    
    # 如果检测结果与现有配置不同，则更新
    if [ "$DETECTED_ARCH" != "$CORE_VERSION" ]; then
        echo -e "$INFO 正在更新 core_version 配置..."
        uci set openclash.config.core_version="$DETECTED_ARCH"
        uci commit openclash
        echo -e "$OK core_version 配置已更新：${Y}$CORE_VERSION${N} → ${G}$DETECTED_ARCH${N}"
    else
        echo -e "$OK 当前配置已是最优版本，无需更新。"
    fi
fi
sleep 1

# ================================================================
# 步骤 6: 初始化配置与内核更新
# ================================================================
print_step "步骤 6/8: 初始化配置与内核更新"
echo -e "$INFO 配置更新分支为 Dev，启用 jsdelivr 加速..."
uci set openclash.config.release_branch=dev
uci set openclash.config.skip_safe_path_check=1
uci set openclash.config.github_address_mod='https://testingcf.jsdelivr.net/'
uci commit openclash
echo -e "$OK 基础配置更新完成。"

echo -e "$INFO 正在调用内部脚本更新内核..."
/usr/share/openclash/openclash_core.sh
if [ $? -ne 0 ]; then
  echo -e "$ERR 内核更新失败，请检查日志。"
  exit 1
fi
echo -e "$OK 内核更新完成。"

# Smart 内核逻辑
CORE_TYPE=$(uci get openclash.config.core_type 2>/dev/null)
if [ "$CORE_TYPE" = "Smart" ]; then
  echo -e "$INFO 检测到 Smart 内核模式，正在配置..."
  uci set openclash.config.auto_smart_switch='1'
  uci set openclash.config.lgbm_auto_update='1'
  uci commit openclash
  
  # 检查用户是否开启了 LGBM 模型
  LGBM_ENABLED=$(uci get openclash.config.smart_enable_lgbm 2>/dev/null)
  
  if [ "$LGBM_ENABLED" = "1" ]; then
    echo -e "$OK 检测到 LGBM 模型已开启，准备下载..."
    echo
    
    # 检测剩余空间（单位：KB）
    AVAILABLE_SPACE=$(df /etc/openclash 2>/dev/null | awk 'NR==2 {print $4}')
    if [ -z "$AVAILABLE_SPACE" ]; then
      AVAILABLE_SPACE=$(df / | awk 'NR==2 {print $4}')
    fi
    
    # 转换为 MB
    AVAILABLE_MB=$((AVAILABLE_SPACE / 1024))
    echo -e "$INFO 检测到可用空间：${G}${AVAILABLE_MB} MB${N}"
    
    # 根据空间选择模型版本
    if [ $AVAILABLE_MB -gt 31 ]; then
      MODEL_VERSION="完整版 (Model-large.bin)"
      MODEL_FILENAME="Model-large.bin"
      MODEL_URL_SUFFIX="Model-large.bin"
      echo -e "$OK 空间充足，将下载${G}完整版${N}模型 (~30MB)"
    elif [ $AVAILABLE_MB -gt 14 ]; then
      MODEL_VERSION="中等版 (Model-middle.bin)"
      MODEL_FILENAME="Model-middle.bin"
      MODEL_URL_SUFFIX="Model-middle.bin"
      echo -e "$INFO 空间有限，将下载${Y}中等版${N}模型 (~13MB)"
    elif [ $AVAILABLE_MB -gt 5 ]; then
      MODEL_VERSION="轻量版 (Model.bin)"
      MODEL_FILENAME="Model.bin"
      MODEL_URL_SUFFIX="Model.bin"
      echo -e "$WARN 空间紧张，将下载${Y}轻量版${N}模型 (~4MB)"
    else
      echo -e "$ERR 可用空间不足 5MB，无法下载任何版本的 LGBM 模型。"
      echo -e "$INFO 正在自动关闭 LGBM 模型功能..."
      uci set openclash.config.smart_enable_lgbm='0'
      uci commit openclash
      echo -e "$WARN LGBM 模型已关闭，Smart 内核将以基础模式运行。"
      MODEL_VERSION=""
    fi
    
    # 如果选择了模型，则下载
    if [ -n "$MODEL_VERSION" ]; then
      # 更新 UCI 配置
      MODEL_CUSTOM_URL="https://github.com/vernesong/mihomo/releases/download/LightGBM-Model/${MODEL_URL_SUFFIX}"
      uci set openclash.config.lgbm_custom_url="$MODEL_CUSTOM_URL"
      uci commit openclash
      echo -e "$INFO 已更新模型 URL 配置：${W}${MODEL_URL_SUFFIX}${N}"
      echo
      
      # 准备下载
      TMP_MODEL="/tmp/${MODEL_FILENAME}"
      TARGET_DIR="/etc/openclash"
      TARGET_FILE="$TARGET_DIR/Model.bin"
      mkdir -p "$TARGET_DIR"
      
      
      if ! command -v curl >/dev/null 2>&1; then
          echo -e "$ERR 未找到 curl。"
          exit 1
      fi
      
      DOWNLOAD_SUCCESS=0
      DIRECT_URL="https://github.com/vernesong/mihomo/releases/download/LightGBM-Model/${MODEL_URL_SUFFIX}"
      MIRROR_URL="https://github-proxy.asailor.org/https://github.com/vernesong/mihomo/releases/download/LightGBM-Model/${MODEL_URL_SUFFIX}"
      
      # Smart 模型下载（优先级: 反代镜像站 > GitHub IP）
      echo -e "$INFO 开始使用反代镜像站下载 ${MODEL_VERSION} (文件较大，请耐心等待)..."
      
      # 重试机制: 最多 3 次
      MAX_MIRROR_RETRIES=3
      RETRY_COUNT=0
      
      while [ $RETRY_COUNT -lt $MAX_MIRROR_RETRIES ]; do
        # curl 下载参数
        # -C - : 断点续传
        # --retry 3 : 连接失败时重试 3 次
        # --retry-delay 2 : 重试间隔 2 秒
        # --progress-bar : 简洁的进度条模式（仅显示进度条和百分比）
        # --http2 : 启用 HTTP/2
        curl -C - -sL --fail --retry 3 --retry-delay 2 --connect-timeout 30 --max-time 1200 --insecure --http2 -o "$TMP_MODEL" "$MIRROR_URL"
        
        if [ $? -eq 0 ] && [ -s "$TMP_MODEL" ]; then
          DOWNLOAD_SUCCESS=1
          break
        else
          RETRY_COUNT=$((RETRY_COUNT + 1))
          if [ $RETRY_COUNT -lt $MAX_MIRROR_RETRIES ]; then
            echo
            echo -e "$WARN 镜像站下载失败，正在重试 ($RETRY_COUNT/$MAX_MIRROR_RETRIES)..."
            sleep 2
            echo
          fi
        fi
      done
      
      if [ $DOWNLOAD_SUCCESS -eq 1 ]; then
        echo
      else
        echo -e "$WARN 反代镜像站下载失败。"
      fi
      
      # 尝试使用 GitHub 直链（配合 IP）
      if [ $DOWNLOAD_SUCCESS -eq 0 ] && [ -n "$GITHUB_COM_IP" ]; then
        echo -e "$INFO 尝试使用 GitHub 直链下载 (通过解析的 IP)..."
        
        # 使用 curl 的 --resolve 参数强制使用解析到的 IP
        curl -C - -sL --fail --retry 3 --retry-delay 2 --connect-timeout 30 --max-time 1200 --insecure --http2 \
          --resolve "github.com:443:${GITHUB_COM_IP}" \
          -o "$TMP_MODEL" "$DIRECT_URL"
        
        if [ $? -eq 0 ] && [ -s "$TMP_MODEL" ]; then
          DOWNLOAD_SUCCESS=1
        fi
      fi

      
      if [ $DOWNLOAD_SUCCESS -eq 1 ]; then
        echo -e "$OK Smart LGBM 模型下载成功。"
        mv -f "$TMP_MODEL" "$TARGET_FILE"
        chmod 644 "$TARGET_FILE"
        echo -e "$OK Smart LGBM 模型 (${MODEL_VERSION}) 更新完成。"
      else
        echo -e "$ERR 下载失败（GitHub 直链和镜像站均失败）。"
        [ -f "$TMP_MODEL" ] && rm -f "$TMP_MODEL"
        echo -e "$ERR Smart 内核需要 LGBM 模型才能正常工作，脚本将退出。"
        exit 1
      fi
    fi
  else
    echo -e "$INFO LGBM 模型未开启，跳过模型下载。"
    echo -e "$INFO Smart 内核将以基础模式运行。"
  fi
else
  echo -e "$INFO Smart 内核未开启，跳过模型更新。"
fi
sleep 1

# ================================================================
# 步骤 7: 更新数据库与订阅
# ================================================================
print_step "步骤 7/8: 更新数据库与订阅"

update_res() {
    NAME=$1
    SCRIPT=$2
    echo -e "${INFO} 正在更新 ${NAME}..."
    $SCRIPT
    if [ $? -eq 0 ]; then
        echo -e "${OK} ${NAME} 更新完成。"
        echo
    else
        echo -e "${ERR} ${NAME} 更新失败。"
        exit 1
    fi
}

update_res "GeoIP Dat 数据库" "/usr/share/openclash/openclash_geoip.sh"
update_res "GeoIP MMDB 数据库" "/usr/share/openclash/openclash_ipdb.sh"
update_res "GeoSite 数据库" "/usr/share/openclash/openclash_geosite.sh"
update_res "GeoASN 数据库" "/usr/share/openclash/openclash_geoasn.sh"
update_res "大陆 IP 白名单" "/usr/share/openclash/openclash_chnroute.sh"

echo -e "${INFO} 正在更新订阅..."

# 捕获脚本输出，成功时不显示，失败时显示
SUBSCRIPTION_OUTPUT=$(/usr/share/openclash/openclash.sh 2>&1)
SUBSCRIPTION_STATUS=$?

if [ $SUBSCRIPTION_STATUS -ne 0 ]; then
    echo "$SUBSCRIPTION_OUTPUT"
    echo -e "${ERR} 订阅更新失败，请检查日志。"
    exit 1
fi
echo -e "${OK} 订阅更新完成。"

# 加载个性化配置（如果存在）
if [ -f /etc/config/openclash-set ]; then
  echo
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
fi
sleep 1

# ================================================================
# 步骤 8: 启动服务
# ================================================================
print_step "步骤 8/8: 启动服务"
echo -e "$INFO 设置开机自启并启动 OpenClash..."
uci set openclash.config.enable='1'
uci commit openclash
/etc/init.d/openclash restart >/dev/null 2>&1
echo -e "$OK OpenClash 启动指令已发送。"

# 等待并检查启动状态
echo -e "$INFO 正在等待 OpenClash 启动..."
MAX_WAIT=60  # 最多等待60秒
WAIT_COUNT=0
START_FAILED=0

while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
  sleep 2
  WAIT_COUNT=$((WAIT_COUNT + 2))
  
  # 获取服务状态
  STATUS_OUTPUT=$(/etc/init.d/openclash status 2>/dev/null)
  
  # 检查是否已成功启动
  if echo "$STATUS_OUTPUT" | grep -q "running"; then
    echo
    echo -e "$OK OpenClash 启动成功！"
    break
  fi
  
  # 检查是否为明确的失败状态
  if echo "$STATUS_OUTPUT" | grep -qE "(inactive|dead|failed|stopped)"; then
    echo
    echo -e "$ERR 检测到 OpenClash 启动失败（状态: inactive/stopped）。"
    echo -e "$INFO 请到 LuCI 界面查看插件日志和内核日志以排查问题。"
    START_FAILED=1
    break
  fi
  
  # 每10秒显示一次进度
  if [ $((WAIT_COUNT % 10)) -eq 0 ]; then
    echo -e "$INFO 已等待 ${WAIT_COUNT}/${MAX_WAIT} 秒..."
  fi
done

# 启动超时判断
if [ $START_FAILED -eq 0 ] && [ $WAIT_COUNT -ge $MAX_WAIT ]; then
  echo
  echo -e "$WARN OpenClash 启动超时（60秒）。"
  echo -e "$INFO 请到 LuCI 界面查看插件日志和内核日志。"
  echo -e "$INFO 或手动重启 OpenClash 服务。"
fi
sleep 1

echo
print_line
echo -e "${G}[OK] 脚本运行完毕！${N}"
echo
