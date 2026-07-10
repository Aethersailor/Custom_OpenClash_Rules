#!/bin/sh
# ================================================================
# Custom_OpenClash_Rules 自动安装脚本
# 项目地址: https://github.com/Aethersailor/Custom_OpenClash_Rules
# 功能: 自动安装/更新 OpenClash Dev 版本及全套配置
# ================================================================

R='\033[1;31m'
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
C='\033[1;36m'
W='\033[1;37m'
N='\033[0m'

INFO="${B}[i]${N}"
WARN="${Y}[!]${N}"
ERR="${R}[x]${N}"
OK="${G}[+]${N}"

REPO_API_URL="https://api.github.com/repos/vernesong/OpenClash/contents/dev?ref=package"
MODEL_API_URL="https://api.github.com/repos/vernesong/mihomo/releases/tags/LightGBM-Model"
JSDELIVR_PACKAGE_PREFIX="https://testingcf.jsdelivr.net/gh/vernesong/OpenClash@refs/heads/package/dev"
RAW_PACKAGE_PREFIX="https://raw.githubusercontent.com/vernesong/OpenClash/package/dev"
GH_PROXY_PREFIX="https://v6.gh-proxy.org/"
GITHUB_HOSTS_URL="https://raw.hellogithub.com/hosts"

OPENCLASH_SHARE_DIR="${OPENCLASH_SHARE_DIR:-/usr/share/openclash}"
OPENCLASH_ETC_DIR="${OPENCLASH_ETC_DIR:-/etc/openclash}"
OPENCLASH_INIT="${OPENCLASH_INIT:-/etc/init.d/openclash}"
OPENCLASH_LOG="${OPENCLASH_LOG:-/tmp/openclash.log}"
OPENCLASH_PRESET="${OPENCLASH_PRESET:-/etc/config/openclash-set}"

PKG_MGR=""
EXT=""
FIREWALL_TYPE=""
DEPENDENCIES=""
TMP_DIR=""
LOCK_DIR="${LOCK_DIR:-/tmp/install_openclash_dev_update.lock}"
FEED_FILE=""
FEED_BACKUP=""
FEED_CHANGED=0
ORIGINAL_GITHUB_MOD=""
RESTORE_GITHUB_MOD=0

API_GITHUB_IP=""
RAW_GITHUB_IP=""
GITHUB_COM_IP=""

print_line() {
    printf '%b\n' "${C}================================================================${N}"
}

print_step() {
    printf '\n'
    print_line
    printf '%b\n' "${W}>> $1${N}"
    print_line
}

log_info() {
    printf '%b\n' "${INFO} $1"
}

log_warn() {
    printf '%b\n' "${WARN} $1"
}

log_error() {
    printf '%b\n' "${ERR} $1" >&2
}

log_ok() {
    printf '%b\n' "${OK} $1"
}

die() {
    log_error "$1"
    exit 1
}

logo() {
    command -v clear >/dev/null 2>&1 && clear
    printf '%b\n' "${C}################################################################${N}"
    printf '%b\n' "${C}#                                                              #${N}"
    printf '%b\n' "${C}#              Custom_OpenClash_Rules Auto Installer           #${N}"
    printf '%b\n' "${C}#     https://github.com/Aethersailor/Custom_OpenClash_Rules   #${N}"
    printf '%b\n' "${C}#                                                              #${N}"
    printf '%b\n' "${C}################################################################${N}"
    printf '%b\n\n' "${W}* OpenClash Dev 在线全自动化安装与更新脚本${N}"
}

restore_feed() {
    if [ "$FEED_CHANGED" -eq 1 ] && [ -n "$FEED_FILE" ] && [ -f "$FEED_BACKUP" ]; then
        cp -p "$FEED_BACKUP" "$FEED_FILE" 2>/dev/null || true
        FEED_CHANGED=0
    fi
}

cleanup() {
    status=$?
    trap - EXIT INT TERM HUP
    restore_feed
    if [ "$RESTORE_GITHUB_MOD" -eq 1 ] && command -v uci >/dev/null 2>&1; then
        uci set openclash.config.github_address_mod="${ORIGINAL_GITHUB_MOD:-https://testingcf.jsdelivr.net/}" 2>/dev/null || true
        uci commit openclash 2>/dev/null || true
    fi
    [ -n "$TMP_DIR" ] && rm -rf "$TMP_DIR"
    rm -f "$LOCK_DIR/pid" 2>/dev/null || true
    rmdir "$LOCK_DIR" 2>/dev/null || true
    exit "$status"
}

init_runtime() {
    [ "$(id -u 2>/dev/null)" = "0" ] || die "请使用 root 用户运行此脚本。"

    if ! mkdir "$LOCK_DIR" 2>/dev/null; then
        lock_pid=$(cat "$LOCK_DIR/pid" 2>/dev/null)
        if [ -n "$lock_pid" ] && kill -0 "$lock_pid" 2>/dev/null; then
            die "检测到另一个安装任务正在运行（PID $lock_pid）。"
        fi
        rm -rf "$LOCK_DIR"
        mkdir "$LOCK_DIR" 2>/dev/null || die "无法创建运行锁：$LOCK_DIR"
    fi
    printf '%s\n' "$$" >"$LOCK_DIR/pid"
    trap cleanup EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    trap 'exit 129' HUP

    TMP_DIR=$(mktemp -d /tmp/openclash-installer.XXXXXX 2>/dev/null) ||
        die "无法创建临时目录。"
}

detect_environment() {
    if command -v opkg >/dev/null 2>&1; then
        PKG_MGR="opkg"
        EXT="ipk"
    elif command -v apk >/dev/null 2>&1; then
        PKG_MGR="apk"
        EXT="apk"
    else
        die "未检测到支持的包管理器（opkg/apk）。"
    fi

    if command -v fw4 >/dev/null 2>&1 || command -v nft >/dev/null 2>&1; then
        FIREWALL_TYPE="nftables"
        DEPENDENCIES="bash dnsmasq-full curl ca-bundle ip-full ruby ruby-yaml kmod-tun kmod-inet-diag unzip kmod-nft-tproxy luci-compat luci luci-base coreutils-sha1sum"
    elif command -v fw3 >/dev/null 2>&1 || command -v iptables >/dev/null 2>&1; then
        FIREWALL_TYPE="iptables"
        DEPENDENCIES="bash iptables dnsmasq-full curl ca-bundle ipset ip-full iptables-mod-tproxy iptables-mod-extra ruby ruby-yaml kmod-tun kmod-inet-diag unzip luci-compat luci luci-base coreutils-sha1sum"
    else
        die "未检测到支持的防火墙架构（fw4/nftables 或 fw3/iptables）。"
    fi

    log_ok "包管理器：$PKG_MGR"
    log_ok "防火墙：$FIREWALL_TYPE"
}

normalize_version() {
    printf '%s\n' "$1" |
        sed -n 's/^\([0-9][0-9.]*[0-9]\)\(-r[0-9][0-9]*\)\{0,1\}$/\1/p'
}

get_installed_version() {
    if [ "$PKG_MGR" = "opkg" ]; then
        raw_version=$(opkg status luci-app-openclash 2>/dev/null |
            awk -F ': ' '/^Version:/{print $2; exit}'
        )
    else
        raw_version=$(apk list -I luci-app-openclash 2>/dev/null |
            sed -n 's/^luci-app-openclash-\([0-9][0-9.]*\).*/\1/p' |
            head -n 1
        )
    fi
    normalize_version "$raw_version"
}

package_update() {
    if [ "$PKG_MGR" = "opkg" ]; then
        opkg update
    else
        apk update
    fi
}

package_install_dependencies() {
    set -f
    # Intentional split: dependency names are stored as a whitespace list.
    # shellcheck disable=SC2086
    set -- $DEPENDENCIES
    set +f
    if [ "$PKG_MGR" = "opkg" ]; then
        opkg install "$@"
    else
        apk add "$@"
    fi
}

set_feed_file() {
    if [ "$PKG_MGR" = "opkg" ]; then
        FEED_FILE="/etc/opkg/distfeeds.conf"
    else
        FEED_FILE="/etc/apk/repositories.d/distfeeds.list"
    fi
}

enable_temporary_nju_mirror() {
    set_feed_file
    [ -f "$FEED_FILE" ] || return 1

    FEED_BACKUP="$TMP_DIR/distfeeds.original"
    feed_candidate="$TMP_DIR/distfeeds.nju"
    cp -p "$FEED_FILE" "$FEED_BACKUP" || return 1
    sed \
        -e 's,https://downloads\.immortalwrt\.org,https://mirror.nju.edu.cn/immortalwrt,g' \
        -e 's,https://mirrors\.vsean\.net/openwrt,https://mirror.nju.edu.cn/immortalwrt,g' \
        "$FEED_BACKUP" >"$feed_candidate" || return 1
    cmp -s "$FEED_BACKUP" "$feed_candidate" && return 1
    FEED_CHANGED=1
    cp "$feed_candidate" "$FEED_FILE" || {
        restore_feed
        return 1
    }
}

install_dependencies() {
    log_info "更新软件源并安装依赖..."
    if package_update && package_install_dependencies; then
        log_ok "依赖安装完成。"
        return 0
    fi

    log_warn "默认软件源安装失败，临时切换至南京大学镜像重试。"
    enable_temporary_nju_mirror || die "无法准备临时镜像配置。"

    if ! package_update || ! package_install_dependencies; then
        die "依赖安装失败，请检查软件源和系统版本。"
    fi

    restore_feed
    log_ok "依赖安装完成，系统软件源已恢复。"
}

check_required_commands() {
    missing=""
    for cmd in awk sed grep curl sha1sum sha256sum wc df mktemp uci ruby; do
        command -v "$cmd" >/dev/null 2>&1 || missing="$missing $cmd"
    done
    [ -z "$missing" ] || die "缺少必要命令：$missing"
}

get_github_hosts() {
    hosts_file="$TMP_DIR/github_hosts.txt"
    log_info "获取 GitHub Hosts 信息..."

    if ! curl -fsSL --retry 2 --connect-timeout 10 --max-time 30 \
        -o "$hosts_file" "$GITHUB_HOSTS_URL"; then
        log_warn "GitHub Hosts 获取失败，将使用系统 DNS 和反代。"
        return 0
    fi

    API_GITHUB_IP=$(awk '$2=="api.github.com"{print $1; exit}' "$hosts_file")
    RAW_GITHUB_IP=$(awk '$2=="raw.githubusercontent.com"{print $1; exit}' "$hosts_file")
    GITHUB_COM_IP=$(awk '$2=="github.com"{print $1; exit}' "$hosts_file")

    [ -n "$API_GITHUB_IP" ] && log_ok "api.github.com：$API_GITHUB_IP"
    [ -n "$RAW_GITHUB_IP" ] && log_ok "raw.githubusercontent.com：$RAW_GITHUB_IP"
    [ -n "$GITHUB_COM_IP" ] && log_ok "github.com：$GITHUB_COM_IP"
}

curl_download() {
    output=$1
    url=$2
    resolve_host=${3:-}
    resolve_ip=${4:-}

    rm -f "$output"
    if [ -n "$resolve_host" ] && [ -n "$resolve_ip" ]; then
        curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 30 --max-time 1200 \
            --resolve "$resolve_host:443:$resolve_ip" -o "$output" "$url"
    else
        curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 30 --max-time 1200 \
            -o "$output" "$url"
    fi
}

fetch_api_json() {
    url=$1
    output=$2

    if [ -n "$API_GITHUB_IP" ] &&
        curl_download "$output" "$url" "api.github.com" "$API_GITHUB_IP"; then
        return 0
    fi

    if curl_download "$output" "$url"; then
        return 0
    fi

    curl_download "$output" "${GH_PROXY_PREFIX}${url}"
}

parse_package_metadata() {
    json_file=$1
    suffix=".$EXT"

    awk -v suffix="$suffix" '
        /"name":/ {
            name=$0
            sub(/^.*"name":[[:space:]]*"/, "", name)
            sub(/".*$/, "", name)
            selected=(substr(name, length(name) - length(suffix) + 1) == suffix)
        }
        selected && /"sha":/ {
            sha=$0
            sub(/^.*"sha":[[:space:]]*"/, "", sha)
            sub(/".*$/, "", sha)
        }
        selected && /"size":/ {
            size=$0
            sub(/^.*"size":[[:space:]]*/, "", size)
            sub(/[^0-9].*$/, "", size)
        }
        selected && /"download_url":/ {
            if (name != "" && sha != "" && size != "") {
                print name "|" sha "|" size
                exit
            }
        }
    ' "$json_file"
}

verify_file_size() {
    file=$1
    expected=$2
    actual=$(wc -c <"$file" 2>/dev/null | tr -d ' ')
    [ -n "$actual" ] && [ "$actual" = "$expected" ]
}

verify_git_blob() {
    file=$1
    expected_sha=$2
    size=$(wc -c <"$file" 2>/dev/null | tr -d ' ')
    actual_sha=$(
        {
            printf 'blob %s\0' "$size"
            cat "$file"
        } | sha1sum | awk '{print $1}'
    )
    [ -n "$actual_sha" ] && [ "$actual_sha" = "$expected_sha" ]
}

verify_package_file() {
    file=$1
    expected_size=$2
    expected_sha=$3

    [ -s "$file" ] || return 1
    verify_file_size "$file" "$expected_size" || return 1
    verify_git_blob "$file" "$expected_sha" || return 1

    if [ "$PKG_MGR" = "opkg" ]; then
        opkg --noaction install "$file" >/dev/null 2>&1
    else
        apk add -s -q --force-overwrite --clean-protected --allow-untrusted \
            "$file" >/dev/null 2>&1
    fi
}

download_openclash_package() {
    file_name=$1
    expected_size=$2
    expected_sha=$3
    output=$4

    jsdelivr_url="${JSDELIVR_PACKAGE_PREFIX}/${file_name}"
    raw_url="${RAW_PACKAGE_PREFIX}/${file_name}"
    proxy_url="${GH_PROXY_PREFIX}${raw_url}"

    log_info "下载顺序：jsDelivr → 反代 → GitHub Raw"

    log_info "尝试从 jsDelivr 下载..."
    if curl_download "$output" "$jsdelivr_url" &&
        verify_package_file "$output" "$expected_size" "$expected_sha"; then
        log_ok "jsDelivr 下载和校验成功。"
        return 0
    fi
    log_warn "jsDelivr 下载或校验失败。"

    log_info "尝试从反代下载..."
    if curl_download "$output" "$proxy_url" &&
        verify_package_file "$output" "$expected_size" "$expected_sha"; then
        log_ok "反代下载和校验成功。"
        return 0
    fi
    log_warn "反代下载或校验失败。"

    log_info "尝试从 GitHub Raw 下载..."
    if curl_download "$output" "$raw_url" "raw.githubusercontent.com" "$RAW_GITHUB_IP" &&
        verify_package_file "$output" "$expected_size" "$expected_sha"; then
        log_ok "GitHub Raw 下载和校验成功。"
        return 0
    fi

    rm -f "$output"
    return 1
}

install_openclash_package() {
    package_file=$1

    if [ "$PKG_MGR" = "opkg" ]; then
        opkg install --force-reinstall "$package_file"
    else
        apk add -q --force-overwrite --clean-protected --allow-untrusted "$package_file"
    fi
}

extract_version_from_filename() {
    printf '%s\n' "$1" |
        sed -n \
            -e 's/^luci-app-openclash-\([0-9][0-9.]*[0-9]\)\.apk$/\1/p' \
            -e 's/^luci-app-openclash_\([0-9][0-9.]*[0-9]\)_all\.ipk$/\1/p'
}

has_cpu_flag() {
    flag=$1
    printf ' %s ' "$CPU_FLAGS" | grep -q " $flag "
}

has_all_cpu_flags() {
    for flag in "$@"; do
        has_cpu_flag "$flag" || return 1
    done
}

detect_mips_float() {
    if grep -qiE 'FPU[[:space:]]*:[[:space:]]*(yes|present)' /proc/cpuinfo 2>/dev/null; then
        printf '%s\n' "hardfloat"
    else
        printf '%s\n' "softfloat"
    fi
}

detect_loongarch_abi() {
    kernel_ver=$(uname -r | cut -d. -f1,2)
    major=${kernel_ver%%.*}
    minor=${kernel_ver#*.}

    if [ "$major" -gt 5 ] || { [ "$major" -eq 5 ] && [ "$minor" -ge 19 ]; }; then
        printf '%s\n' "abi2"
    else
        printf '%s\n' "abi1"
    fi
}

detect_core_arch() {
    arch=${CPU_ARCH_OVERRIDE:-$(uname -m)}

    case "$arch" in
        x86_64)
            CPU_FLAGS=${CPU_FLAGS_OVERRIDE:-$(grep -m1 -E '^flags[[:space:]]*:' /proc/cpuinfo 2>/dev/null | cut -d: -f2)}

            if has_all_cpu_flags cx16 lahf_lm popcnt pni sse4_1 sse4_2 ssse3 &&
                has_all_cpu_flags avx avx2 bmi1 bmi2 f16c fma movbe &&
                { has_cpu_flag lzcnt || has_cpu_flag abm; }; then
                printf '%s\n' "linux-amd64-v3"
            elif has_all_cpu_flags cx16 lahf_lm popcnt pni sse4_1 sse4_2 ssse3; then
                printf '%s\n' "linux-amd64-v2"
            else
                printf '%s\n' "linux-amd64-v1"
            fi
            ;;
        i386 | i486 | i586 | i686)
            printf '%s\n' "linux-386"
            ;;
        aarch64 | arm64)
            printf '%s\n' "linux-arm64"
            ;;
        armv7l | armv7)
            printf '%s\n' "linux-armv7"
            ;;
        armv6l | armv6)
            printf '%s\n' "linux-armv6"
            ;;
        armv5tel | armv5)
            printf '%s\n' "linux-armv5"
            ;;
        mips64)
            printf '%s\n' "linux-mips64"
            ;;
        mips64el)
            printf '%s\n' "linux-mips64le"
            ;;
        mips)
            printf 'linux-mips-%s\n' "$(detect_mips_float)"
            ;;
        mipsel)
            printf 'linux-mipsle-%s\n' "$(detect_mips_float)"
            ;;
        loongarch64)
            printf 'linux-loong64-%s\n' "$(detect_loongarch_abi)"
            ;;
        riscv64)
            printf '%s\n' "linux-riscv64"
            ;;
        s390x)
            printf '%s\n' "linux-s390x"
            ;;
        *)
            return 1
            ;;
    esac
}

core_asset_exists() {
    core_arch=$1
    release_branch=$(uci -q get openclash.config.release_branch || printf '%s' dev)
    core_type=$(get_effective_core_type)
    if [ "$core_type" = "Smart" ]; then
        core_dir="smart"
    else
        core_dir="meta"
    fi

    jsdelivr_url="https://testingcf.jsdelivr.net/gh/vernesong/OpenClash@core/${release_branch}/${core_dir}/clash-${core_arch}.tar.gz"
    raw_url="https://raw.githubusercontent.com/vernesong/OpenClash/core/${release_branch}/${core_dir}/clash-${core_arch}.tar.gz"
    proxy_url="${GH_PROXY_PREFIX}${raw_url}"

    if curl -fsIL --retry 2 --connect-timeout 10 --max-time 30 \
        "$jsdelivr_url" >/dev/null 2>&1; then
        return 0
    fi

    if curl -fsIL --retry 2 --connect-timeout 10 --max-time 30 \
        "$proxy_url" >/dev/null 2>&1; then
        return 0
    fi

    if [ -n "$RAW_GITHUB_IP" ]; then
        curl -fsIL --retry 2 --connect-timeout 10 --max-time 30 \
            --resolve "raw.githubusercontent.com:443:$RAW_GITHUB_IP" \
            "$raw_url" >/dev/null 2>&1
    else
        curl -fsIL --retry 2 --connect-timeout 10 --max-time 30 \
            "$raw_url" >/dev/null 2>&1
    fi
}

configure_core_arch() {
    current=$(uci -q get openclash.config.core_version)
    detected=$(detect_core_arch) || die "无法识别当前 CPU 架构。"
    core_asset_exists "$detected" || die "官方仓库中不存在匹配的内核资源：$detected"

    if [ "$current" != "$detected" ]; then
        uci set openclash.config.core_version="$detected" ||
            die "无法写入 core_version。"
        uci commit openclash || die "无法提交 core_version。"
    fi
    log_ok "内核架构：$detected"
}

get_effective_core_type() {
    smart_enable=$(uci -q get openclash.config.smart_enable)
    core_type=$(uci -q get openclash.config.core_type)
    [ "$smart_enable" = "1" ] && core_type="Smart"
    [ -n "$core_type" ] || core_type="Meta"
    printf '%s\n' "$core_type"
}

get_core_path() {
    small_flash=$(uci -q get openclash.config.small_flash_memory)
    if [ "$small_flash" = "1" ]; then
        printf '%s\n' "/tmp/etc/openclash/core/clash_meta"
    else
        printf '%s\n' "$OPENCLASH_ETC_DIR/core/clash_meta"
    fi
}

verify_core_version() {
    core_type=$1
    core_path=$(get_core_path)
    [ -x "$core_path" ] || return 1
    [ -s /tmp/clash_last_version ] || return 1

    if [ "$core_type" = "Smart" ]; then
        expected=$(sed -n '2p' /tmp/clash_last_version)
    else
        expected=$(sed -n '1p' /tmp/clash_last_version)
    fi
    actual=$("$core_path" -v 2>/dev/null | awk 'NR==1{print $3}')

    [ -n "$expected" ] && [ "$actual" = "$expected" ]
}

update_core() {
    core_script="$OPENCLASH_SHARE_DIR/openclash_core.sh"
    [ -x "$core_script" ] || die "内核更新脚本不存在：$core_script"

    core_type=$(get_effective_core_type)
    for source in "https://testingcf.jsdelivr.net/" "$GH_PROXY_PREFIX" "0"; do
        rm -f /tmp/clash_last_version
        log_info "更新 $core_type 内核，下载源：$source"
        "$core_script" "$core_type" "$source" >/dev/null 2>&1 || true

        if verify_core_version "$core_type"; then
            log_ok "$core_type 内核版本验证通过。"
            return 0
        fi
        log_warn "$core_type 内核更新或版本验证失败，切换下载源。"
    done

    die "$core_type 内核更新失败。"
}

parse_release_asset() {
    json_file=$1
    target_name=$2

    awk -v target="$target_name" '
        /"name":/ {
            name=$0
            sub(/^.*"name":[[:space:]]*"/, "", name)
            sub(/".*$/, "", name)
            selected=(name == target)
        }
        selected && /"size":/ {
            size=$0
            sub(/^.*"size":[[:space:]]*/, "", size)
            sub(/[^0-9].*$/, "", size)
        }
        selected && /"digest":/ {
            digest=$0
            sub(/^.*"digest":[[:space:]]*"sha256:/, "", digest)
            sub(/".*$/, "", digest)
        }
        selected && /"browser_download_url":/ {
            url=$0
            sub(/^.*"browser_download_url":[[:space:]]*"/, "", url)
            sub(/".*$/, "", url)
            if (size != "" && digest != "" && url != "") {
                print size "|" digest "|" url
                exit
            }
        }
    ' "$json_file"
}

available_kb() {
    df -Pk "$1" 2>/dev/null | awk 'NR==2{print $4}'
}

model_fits() {
    size_bytes=$1
    required_kb=$((size_bytes / 1024 + 2048))
    tmp_kb=$(available_kb "$TMP_DIR")
    target_kb=$(available_kb "$OPENCLASH_ETC_DIR")
    [ -n "$tmp_kb" ] && [ -n "$target_kb" ] &&
        [ "$tmp_kb" -gt "$required_kb" ] &&
        [ "$target_kb" -gt "$required_kb" ]
}

verify_sha256() {
    file=$1
    expected=$2
    actual=$(sha256sum "$file" | awk '{print $1}')
    [ -n "$actual" ] && [ "$actual" = "$expected" ]
}

update_smart_model() {
    [ "$(get_effective_core_type)" = "Smart" ] || {
        log_info "Smart 内核未启用，跳过 LGBM 模型。"
        return 0
    }

    uci set openclash.config.auto_smart_switch='1' ||
        die "无法配置 Smart 自动切换。"
    uci set openclash.config.lgbm_auto_update='1' ||
        die "无法配置 LGBM 自动更新。"
    uci commit openclash || die "无法提交 Smart 内核配置。"

    [ "$(uci -q get openclash.config.smart_enable_lgbm)" = "1" ] || {
        log_info "LGBM 模型未启用，跳过模型下载。"
        return 0
    }

    mkdir -p "$OPENCLASH_ETC_DIR" || die "无法创建 OpenClash 数据目录。"

    model_json="$TMP_DIR/model-release.json"
    fetch_api_json "$MODEL_API_URL" "$model_json" ||
        die "无法获取 LGBM 模型元数据。"

    selected=""
    for candidate in Model-large.bin Model-middle.bin Model.bin; do
        metadata=$(parse_release_asset "$model_json" "$candidate")
        [ -n "$metadata" ] || continue
        size=${metadata%%|*}
        rest=${metadata#*|}
        digest=${rest%%|*}
        url=${rest#*|}
        if model_fits "$size"; then
            selected=$candidate
            break
        fi
    done

    if [ -z "$selected" ]; then
        if [ -s "$OPENCLASH_ETC_DIR/Model.bin" ]; then
            log_warn "空间不足，保留现有 LGBM 模型。"
            return 0
        fi
        die "空间不足，且没有可保留的 LGBM 模型。"
    fi

    model_tmp="$TMP_DIR/$selected"
    proxy_url="${GH_PROXY_PREFIX}${url}"
    log_info "下载 LGBM 模型：$selected"

    if ! curl_download "$model_tmp" "$proxy_url" ||
        ! verify_file_size "$model_tmp" "$size" ||
        ! verify_sha256 "$model_tmp" "$digest"; then
        log_warn "反代下载或校验失败，尝试 GitHub 直链。"
        if ! curl_download "$model_tmp" "$url" "github.com" "$GITHUB_COM_IP" ||
            ! verify_file_size "$model_tmp" "$size" ||
            ! verify_sha256 "$model_tmp" "$digest"; then
            die "LGBM 模型下载或 SHA-256 校验失败。"
        fi
    fi

    mv -f "$model_tmp" "$OPENCLASH_ETC_DIR/Model.bin" ||
        die "无法安装 LGBM 模型。"
    chmod 644 "$OPENCLASH_ETC_DIR/Model.bin" ||
        die "无法设置 LGBM 模型权限。"

    uci set openclash.config.lgbm_custom_url="$url" ||
        die "无法配置 LGBM 模型 URL。"
    uci commit openclash || die "无法提交 LGBM 模型配置。"
    log_ok "LGBM 模型更新并校验完成：$selected"
}

log_line_count() {
    if [ -f "$OPENCLASH_LOG" ]; then
        wc -l <"$OPENCLASH_LOG" | tr -d ' '
    else
        printf '%s\n' "0"
    fi
}

new_log_has_error() {
    start_line=$1
    [ -f "$OPENCLASH_LOG" ] || return 1
    sed -n "$((start_line + 1)),\$p" "$OPENCLASH_LOG" |
        grep -qE 'Update Error|Download Failed|Update Failed|Core Version Check Error|Unable To Parse|Format Validation Failed'
}

new_log_has_subscription_error() {
    start_line=$1
    [ -f "$OPENCLASH_LOG" ] || return 1
    sed -n "$((start_line + 1)),\$p" "$OPENCLASH_LOG" |
        grep -qE '【.*】Update Error, Please Try Again Later'
}

valid_data_file() {
    file=$1
    min_size=${2:-10240}
    [ -s "$file" ] || return 1
    size=$(wc -c <"$file" 2>/dev/null | tr -d ' ')
    [ "$size" -ge "$min_size" ] || return 1
    ! head -c 512 "$file" | grep -qiE '<!doctype|<html|<head|<body'
}

valid_mmdb_file() {
    file=$1
    valid_data_file "$file" 10240 || return 1
    tail -c 256 "$file" 2>/dev/null | grep -q 'MaxMind.com'
}

validate_geo_databases() {
    valid_data_file "$OPENCLASH_ETC_DIR/GeoIP.dat" &&
        valid_data_file "$OPENCLASH_ETC_DIR/GeoSite.dat" &&
        valid_mmdb_file "$OPENCLASH_ETC_DIR/ASN.mmdb" &&
        valid_mmdb_file "$OPENCLASH_ETC_DIR/Country.mmdb"
}

run_geo_update_once() {
    geo_script=$1
    shift
    start_line=$(log_line_count)
    "$geo_script" "$@" >/dev/null 2>&1 || return 1
    new_log_has_error "$start_line" && return 1
    validate_geo_databases
}

update_geo_databases() {
    geo_script="$OPENCLASH_SHARE_DIR/openclash_geo.sh"

    if [ -x "$geo_script" ]; then
        original_source=$(uci -q get openclash.config.github_address_mod)
        ORIGINAL_GITHUB_MOD=$original_source
        RESTORE_GITHUB_MOD=1
        for source in "https://testingcf.jsdelivr.net/" "$GH_PROXY_PREFIX" "0"; do
            uci set openclash.config.github_address_mod="$source" ||
                die "无法切换 Geo 数据库下载源。"
            uci commit openclash || die "无法提交 Geo 数据库下载源。"
            log_info "更新 Geo 数据库，下载源：$source"
            if run_geo_update_once "$geo_script" all; then
                uci set openclash.config.github_address_mod="${original_source:-https://testingcf.jsdelivr.net/}" ||
                    die "无法恢复 GitHub 下载源。"
                uci commit openclash || die "无法提交 GitHub 下载源。"
                RESTORE_GITHUB_MOD=0
                log_ok "GeoIP、GeoSite、ASN 和 Country 数据库验证通过。"
                return 0
            fi
            log_warn "Geo 数据库更新失败，切换下载源。"
        done
        uci set openclash.config.github_address_mod="${original_source:-https://testingcf.jsdelivr.net/}" ||
            die "无法恢复 GitHub 下载源。"
        uci commit openclash || die "无法提交 GitHub 下载源。"
        RESTORE_GITHUB_MOD=0
        die "Geo 数据库更新失败。"
    fi

    for legacy in \
        openclash_geoip.sh \
        openclash_ipdb.sh \
        openclash_geosite.sh \
        openclash_geoasn.sh; do
        script="$OPENCLASH_SHARE_DIR/$legacy"
        [ -x "$script" ] || die "数据库更新脚本不存在：$script"
        start_line=$(log_line_count)
        "$script" >/dev/null 2>&1 || die "执行数据库更新脚本失败：$legacy"
        new_log_has_error "$start_line" && die "数据库更新失败：$legacy"
    done

    validate_geo_databases || die "数据库文件完整性验证失败。"
    log_ok "旧版 Geo 数据库更新与验证完成。"
}

validate_chnroute() {
    small_flash=$(uci -q get openclash.config.small_flash_memory)
    if [ "$small_flash" = "1" ]; then
        base="/tmp/etc/openclash"
    else
        base="$OPENCLASH_ETC_DIR"
    fi
    valid_data_file "$base/china_ip_route.ipset" 1024 &&
        valid_data_file "$base/china_ip6_route.ipset" 256
}

update_chnroute() {
    script="$OPENCLASH_SHARE_DIR/openclash_chnroute.sh"
    [ -x "$script" ] || die "大陆 IP 更新脚本不存在：$script"
    start_line=$(log_line_count)
    "$script" >/dev/null 2>&1 || die "大陆 IP 更新脚本执行失败。"
    new_log_has_error "$start_line" && die "大陆 IP 白名单更新失败。"
    validate_chnroute || die "大陆 IP 白名单文件验证失败。"
    log_ok "大陆 IPv4/IPv6 白名单更新与验证完成。"
}

validate_yaml_file() {
    file=$1
    [ -s "$file" ] || return 1
    ruby -ryaml -rYAML -I "$OPENCLASH_SHARE_DIR" -E UTF-8 \
        -e 'YAML.load_file(ARGV[0])' "$file" >/dev/null 2>&1
}

update_subscriptions() {
    script="$OPENCLASH_SHARE_DIR/openclash.sh"
    [ -x "$script" ] || die "订阅更新脚本不存在：$script"

    subscription_count=$(uci -q show openclash 2>/dev/null |
        grep -c '=config_subscribe' || true)
    if [ "$subscription_count" -eq 0 ]; then
        log_info "未配置订阅，跳过订阅更新。"
        return 0
    fi

    start_line=$(log_line_count)
    "$script" >/dev/null 2>&1 || die "订阅更新脚本执行失败。"
    new_log_has_subscription_error "$start_line" && die "至少一个订阅更新失败。"
    log_ok "订阅更新完成。"
}

apply_user_preset() {
    [ -f "$OPENCLASH_PRESET" ] || return 0
    log_info "执行用户个性化配置：$OPENCLASH_PRESET"
    sh "$OPENCLASH_PRESET" || die "用户个性化配置执行失败。"
    log_ok "用户个性化配置覆盖完成。"
}

validate_final_config() {
    config_path=$(uci -q get openclash.config.config_path)
    [ -n "$config_path" ] || die "OpenClash 未配置 config_path。"
    validate_yaml_file "$config_path" || die "最终配置文件不存在或 YAML 解析失败：$config_path"

    core_path=$(get_core_path)
    [ -x "$core_path" ] || die "OpenClash 内核不存在或不可执行：$core_path"
    "$core_path" -t -d "$OPENCLASH_ETC_DIR" -f "$config_path" >/dev/null 2>&1 ||
        die "最终配置未通过 Mihomo 内核校验。"
    log_ok "最终配置通过 YAML 和 Mihomo 双重校验。"
}

start_openclash() {
    [ -x "$OPENCLASH_INIT" ] || die "OpenClash 服务脚本不存在：$OPENCLASH_INIT"

    uci set openclash.config.enable='1' || die "无法启用 OpenClash 配置。"
    uci commit openclash || die "无法提交 OpenClash 启用状态。"
    "$OPENCLASH_INIT" enable >/dev/null 2>&1 ||
        die "设置 OpenClash 开机自启失败。"
    "$OPENCLASH_INIT" restart >/dev/null 2>&1 ||
        die "OpenClash 重启命令执行失败。"

    waited=0
    while [ "$waited" -lt 90 ]; do
        sleep 3
        waited=$((waited + 3))
        status=$("$OPENCLASH_INIT" status 2>/dev/null)
        if printf '%s\n' "$status" | grep -q 'running' && pidof clash >/dev/null 2>&1; then
            log_ok "OpenClash 启动成功。"
            return 0
        fi
        if printf '%s\n' "$status" | grep -qE 'inactive|dead|failed|stopped'; then
            die "OpenClash 启动失败，服务状态：$status"
        fi
        [ $((waited % 15)) -eq 0 ] && log_info "等待 OpenClash 启动：${waited}/90 秒"
    done

    die "OpenClash 启动超时。"
}

main() {
    logo
    log_info "即将安装或升级 OpenClash Dev，并验证所有配套资源。"
    init_runtime

    print_step "步骤 1/8: 系统环境检测"
    detect_environment
    installed=$(get_installed_version)
    if [ -n "$installed" ]; then
        log_ok "已安装 OpenClash v$installed"
    else
        log_info "当前未安装 OpenClash。"
    fi

    print_step "步骤 2/8: 安装依赖"
    install_dependencies
    check_required_commands

    print_step "步骤 3/8: 获取 GitHub 网络信息"
    get_github_hosts

    print_step "步骤 4/8: 下载并安装 OpenClash Dev"
    package_json="$TMP_DIR/package.json"
    fetch_api_json "$REPO_API_URL" "$package_json" ||
        die "无法获取 OpenClash Dev 包元数据。"
    metadata=$(parse_package_metadata "$package_json")
    [ -n "$metadata" ] || die "未在官方仓库找到 .$EXT 安装包。"

    file_name=${metadata%%|*}
    rest=${metadata#*|}
    expected_sha=${rest%%|*}
    expected_size=${rest#*|}
    target_version=$(extract_version_from_filename "$file_name")
    [ -n "$target_version" ] || die "无法从文件名解析目标版本：$file_name"

    package_file="$TMP_DIR/openclash.$EXT"
    download_openclash_package "$file_name" "$expected_size" "$expected_sha" "$package_file" ||
        die "所有安装包下载源均失败，或文件校验未通过。"
    install_openclash_package "$package_file" || die "OpenClash 安装失败。"

    installed=$(get_installed_version)
    [ "$installed" = "$target_version" ] ||
        die "安装后版本不匹配：目标 $target_version，实际 ${installed:-未知}"
    log_ok "OpenClash Dev v$installed 安装并验证完成。"

    print_step "步骤 5/8: 初始化配置与架构"
    uci set openclash.config.release_branch='dev' ||
        die "无法配置 OpenClash Dev 分支。"
    uci set openclash.config.skip_safe_path_check='1' ||
        die "无法配置安全路径检查选项。"
    uci set openclash.config.github_address_mod='https://testingcf.jsdelivr.net/' ||
        die "无法配置 GitHub 下载源。"
    uci commit openclash || die "基础配置提交失败。"
    configure_core_arch

    print_step "步骤 6/8: 更新内核与 Smart 模型"
    update_core
    update_smart_model

    print_step "步骤 7/8: 更新数据库、订阅和个性化配置"
    update_geo_databases
    update_chnroute
    update_subscriptions
    apply_user_preset
    validate_final_config

    print_step "步骤 8/8: 启动并验证服务"
    start_openclash

    printf '\n'
    print_line
    printf '%b\n' "${G}[OK] OpenClash Dev 安装、更新和验证全部完成。${N}"
}

if [ "${OPENCLASH_INSTALLER_LIB_ONLY:-0}" != "1" ]; then
    main "$@"
fi
