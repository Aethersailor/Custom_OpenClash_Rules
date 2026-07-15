#!/bin/sh
# ================================================================
# Custom_OpenClash_Rules OpenClash Dev 更新脚本
# 项目地址: https://github.com/Aethersailor/Custom_OpenClash_Rules
# 功能: 检查依赖后安装/更新 OpenClash Dev 插件包及内核，并验证服务启动
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

OPENCLASH_REPO_URL="https://github.com/vernesong/OpenClash.git"
PACKAGE_REF="refs/heads/package"
GIT_REFS_URL="${OPENCLASH_REPO_URL}/info/refs?service=git-upload-pack"
JSDELIVR_METADATA_PREFIX="https://data.jsdelivr.com/v1/package/gh/vernesong/OpenClash@"
JSDELIVR_PACKAGE_PREFIX="https://testingcf.jsdelivr.net/gh/vernesong/OpenClash@"
RAW_PACKAGE_PREFIX="https://raw.githubusercontent.com/vernesong/OpenClash"
GH_PROXY_PREFIX="https://v6.gh-proxy.org/"
PACKAGE_RESOLVE_RETRIES="${PACKAGE_RESOLVE_RETRIES:-3}"
PACKAGE_REF_CONNECT_TIMEOUT="${PACKAGE_REF_CONNECT_TIMEOUT:-8}"
PACKAGE_REF_MAX_TIME="${PACKAGE_REF_MAX_TIME:-25}"

OPENCLASH_SHARE_DIR="${OPENCLASH_SHARE_DIR:-/usr/share/openclash}"
OPENCLASH_ETC_DIR="${OPENCLASH_ETC_DIR:-/etc/openclash}"
OPENCLASH_INIT="${OPENCLASH_INIT:-/etc/init.d/openclash}"

PKG_MGR=""
EXT=""
FIREWALL_TYPE=""
DEPENDENCIES=""
TMP_DIR=""
LOCK_DIR="${LOCK_DIR:-/tmp/install_openclash_dev.lock}"
FEED_FILE=""
FEED_BACKUP=""
FEED_CHANGED=0
PACKAGE_COMMIT=""
PACKAGE_TARGET_VERSION=""

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
    printf '%b\n\n' "${W}* OpenClash Dev 插件与内核更新脚本${N}"
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
            die "检测到另一个 OpenClash 更新任务正在运行（PID $lock_pid）。"
        fi
        rm -rf "$LOCK_DIR"
        mkdir "$LOCK_DIR" 2>/dev/null || die "无法创建运行锁：$LOCK_DIR"
    fi
    printf '%s\n' "$$" >"$LOCK_DIR/pid"
    trap cleanup EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    trap 'exit 129' HUP

    TMP_DIR=$(mktemp -d /tmp/openclash-dev-update.XXXXXX 2>/dev/null) ||
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
        DEPENDENCIES="bash dnsmasq-full curl ca-bundle ip-full ruby ruby-yaml kmod-tun kmod-inet-diag unzip kmod-nft-tproxy luci-compat luci luci-base coreutils-sha256sum"
    elif command -v fw3 >/dev/null 2>&1 || command -v iptables >/dev/null 2>&1; then
        FIREWALL_TYPE="iptables"
        DEPENDENCIES="bash iptables dnsmasq-full curl ca-bundle ipset ip-full iptables-mod-tproxy iptables-mod-extra ruby ruby-yaml kmod-tun kmod-inet-diag unzip luci-compat luci luci-base coreutils-sha256sum"
    else
        die "未检测到支持的防火墙架构（fw4/nftables 或 fw3/iptables）。"
    fi

    log_ok "包管理器：$PKG_MGR"
    log_ok "防火墙：$FIREWALL_TYPE"
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
    log_info "更新软件源并检查/安装 OpenClash 依赖..."
    if package_update && package_install_dependencies; then
        log_ok "软件源更新及依赖检查完成。"
        return 0
    fi

    log_warn "默认软件源处理失败，临时切换至南京大学镜像重试。"
    enable_temporary_nju_mirror || die "无法准备临时镜像配置。"

    if ! package_update || ! package_install_dependencies; then
        die "依赖检查或安装失败，请检查软件源和系统版本。"
    fi

    restore_feed
    log_ok "依赖检查完成，系统软件源已恢复。"
}

check_required_commands() {
    missing=""
    for cmd in awk sed grep curl sha256sum wc mktemp uci uname ruby; do
        command -v "$cmd" >/dev/null 2>&1 || missing="$missing $cmd"
    done
    [ -z "$missing" ] || die "缺少必要命令：$missing"
}

curl_download() {
    output=$1
    url=$2

    rm -f "$output"
    curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 30 --max-time 1200 \
        -o "$output" "$url"
}

fetch_package_refs_route() {
    route=$1
    output=$2
    rm -f "$output"

    case "$route" in
        direct)
            url=$GIT_REFS_URL
            ;;
        proxy)
            url="${GH_PROXY_PREFIX}${GIT_REFS_URL}"
            ;;
        *)
            return 1
            ;;
    esac

    curl -fsSL --connect-timeout "$PACKAGE_REF_CONNECT_TIMEOUT" \
        --max-time "$PACKAGE_REF_MAX_TIME" \
        -H 'Cache-Control: no-cache' -H 'Pragma: no-cache' \
        -o "$output" "$url" 2>/dev/null || return 1
    grep -aq '# service=git-upload-pack' "$output"
}

package_ref_route_label() {
    case "$1" in
        direct) printf '%s\n' 'GitHub Smart HTTP 直连' ;;
        proxy) printf '%s\n' 'GitHub Smart HTTP 反代' ;;
        *) printf '%s\n' "$1" ;;
    esac
}

fetch_package_branch_sha() {
    refs_file="$TMP_DIR/package-refs"
    route_file="$TMP_DIR/package-ref-route"
    selected_route=""

    if [ -s "$route_file" ]; then
        cached_route=$(cat "$route_file" 2>/dev/null)
        if fetch_package_refs_route "$cached_route" "$refs_file"; then
            selected_route=$cached_route
        else
            rm -f "$route_file"
        fi
    fi

    if [ -z "$selected_route" ]; then
        for route in direct proxy; do
            label=$(package_ref_route_label "$route")
            log_info "探测官方 package 分支：$label" >&2
            if fetch_package_refs_route "$route" "$refs_file"; then
                selected_route=$route
                printf '%s\n' "$route" >"$route_file"
                log_ok "官方提交探测路径：$label" >&2
                break
            fi
            log_warn "$label 不可用，切换下一条路径。" >&2
        done
    fi

    [ -n "$selected_route" ] || return 1

    sha=$(awk -v ref="$PACKAGE_REF" '
        {
            marker=" " ref
            pos=index($0, marker)
            if (pos > 40) {
                candidate=substr($0, pos - 40, 40)
                if (length(candidate) == 40 && candidate !~ /[^0-9a-f]/) {
                    print candidate
                    exit
                }
            }
        }
    ' "$refs_file")
    case "$sha" in
        '' | *[!0-9a-f]*) return 1 ;;
    esac
    [ "${#sha}" -eq 40 ] || return 1
    printf '%s\n' "$sha"
}

download_commit_file() {
    commit=$1
    path=$2
    output=$3
    raw_url="${RAW_PACKAGE_PREFIX}/${commit}/dev/${path}"
    jsdelivr_url="${JSDELIVR_PACKAGE_PREFIX}${commit}/dev/${path}"
    proxy_url="${GH_PROXY_PREFIX}${raw_url}"

    curl_download "$output" "$jsdelivr_url" ||
        curl_download "$output" "$proxy_url" ||
        curl_download "$output" "$raw_url"
}

fetch_package_metadata() {
    commit=$1
    output=$2
    curl_download "$output" "${JSDELIVR_METADATA_PREFIX}${commit}/flat"
}

parse_package_metadata() {
    json_file=$1
    suffix=".$EXT"

    awk -v suffix="$suffix" '
        /"name":/ {
            name=$0
            sub(/^.*"name":[[:space:]]*"/, "", name)
            sub(/".*$/, "", name)
            hash=""
            size=""
            selected=(index(name, "/dev/luci-app-openclash") == 1 &&
                substr(name, length(name) - length(suffix) + 1) == suffix)
        }
        selected && /"hash":/ {
            hash=$0
            sub(/^.*"hash":[[:space:]]*"/, "", hash)
            sub(/".*$/, "", hash)
        }
        selected && /"size":/ {
            size=$0
            sub(/^.*"size":[[:space:]]*/, "", size)
            sub(/[^0-9].*$/, "", size)
            if (name != "" && hash != "" && size != "") {
                sub(/^\/dev\//, "", name)
                print name "|" hash "|" size
                exit
            }
        }
    ' "$json_file"
}

parse_package_version() {
    sed -n '1s/^v\([0-9][0-9.]*[0-9]\)\r*$/\1/p' "$1"
}

resolve_package_metadata() {
    commit=$1
    metadata_file="$TMP_DIR/package-metadata.json"
    version_file="$TMP_DIR/package-version"

    if fetch_package_metadata "$commit" "$metadata_file"; then
        metadata=$(parse_package_metadata "$metadata_file")
        if [ -n "$metadata" ]; then
            printf '%s\n' "$metadata"
            return 0
        fi
    fi

    download_commit_file "$commit" version "$version_file" || return 1
    version=$(parse_package_version "$version_file")
    [ -n "$version" ] || return 1
    case "$EXT" in
        apk) file_name="luci-app-openclash-${version}.apk" ;;
        ipk) file_name="luci-app-openclash_${version}_all.ipk" ;;
        *) return 1 ;;
    esac
    printf '%s||\n' "$file_name"
}

verify_file_size() {
    file=$1
    expected=$2
    actual=$(wc -c <"$file" 2>/dev/null | tr -d ' ')
    [ -n "$actual" ] && [ "$actual" = "$expected" ]
}

verify_sha256_base64() {
    file=$1
    expected_base64=$2
    expected_hex=$(ruby -e 'print ARGV[0].unpack1("m0").unpack1("H*")' \
        "$expected_base64" 2>/dev/null) || return 1
    actual_hex=$(sha256sum "$file" | awk '{print $1}')
    [ "${#expected_hex}" -eq 64 ] && [ "$actual_hex" = "$expected_hex" ]
}

verify_package_file() {
    file=$1
    expected_size=$2
    expected_hash=$3

    [ -s "$file" ] || return 1
    [ -z "$expected_size" ] || verify_file_size "$file" "$expected_size" || return 1
    [ -z "$expected_hash" ] || verify_sha256_base64 "$file" "$expected_hash" || return 1

    if [ "$PKG_MGR" = "opkg" ]; then
        opkg --noaction install "$file" >/dev/null 2>&1
    else
        apk add -s -q --force-overwrite --clean-protected --allow-untrusted \
            "$file" >/dev/null 2>&1
    fi
}

download_openclash_package() {
    commit=$1
    file_name=$2
    expected_size=$3
    expected_hash=$4
    output=$5

    raw_url="${RAW_PACKAGE_PREFIX}/${commit}/dev/${file_name}"
    jsdelivr_url="${JSDELIVR_PACKAGE_PREFIX}${commit}/dev/${file_name}"
    proxy_url="${GH_PROXY_PREFIX}${raw_url}"

    log_info "下载顺序：jsDelivr → 反代 → GitHub Raw（均锁定提交 $commit）"

    log_info "尝试从 jsDelivr 下载..."
    if curl_download "$output" "$jsdelivr_url" &&
        verify_package_file "$output" "$expected_size" "$expected_hash"; then
        log_ok "jsDelivr 下载和校验成功。"
        return 0
    fi

    log_info "尝试从反代下载..."
    if curl_download "$output" "$proxy_url" &&
        verify_package_file "$output" "$expected_size" "$expected_hash"; then
        log_ok "反代下载和校验成功。"
        return 0
    fi

    log_info "尝试从 GitHub Raw 下载..."
    if curl_download "$output" "$raw_url" &&
        verify_package_file "$output" "$expected_size" "$expected_hash"; then
        log_ok "GitHub Raw 下载和校验成功。"
        return 0
    fi

    rm -f "$output"
    return 1
}

prepare_latest_package() {
    output=$1
    attempt=1

    while [ "$attempt" -le "$PACKAGE_RESOLVE_RETRIES" ]; do
        before=$(fetch_package_branch_sha) || return 1
        log_info "官方 package 分支提交：$before"

        metadata=$(resolve_package_metadata "$before") || return 1
        file_name=${metadata%%|*}
        rest=${metadata#*|}
        expected_hash=${rest%%|*}
        expected_size=${rest#*|}
        target_version=$(extract_version_from_filename "$file_name")
        [ -n "$target_version" ] || return 1

        if [ -z "$expected_hash" ] || [ -z "$expected_size" ]; then
            log_warn "提交已锁定，但校验元数据不可用，将使用官方提交直链和包管理器结构校验。"
        fi

        download_openclash_package "$before" "$file_name" \
            "$expected_size" "$expected_hash" "$output" || return 1

        after=$(fetch_package_branch_sha) || return 1
        if [ "$before" = "$after" ]; then
            PACKAGE_COMMIT=$before
            PACKAGE_TARGET_VERSION=$target_version
            return 0
        fi

        log_warn "下载期间官方 package 分支已从 $before 更新为 $after，重新获取最新版。"
        rm -f "$output"
        attempt=$((attempt + 1))
    done

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

install_latest_openclash_package() {
    package_file=$1
    install_round=1

    while [ "$install_round" -le "$PACKAGE_RESOLVE_RETRIES" ]; do
        prepare_latest_package "$package_file" || return 1
        target_version=$PACKAGE_TARGET_VERSION
        install_openclash_package "$package_file" || return 1

        installed=$(get_installed_version)
        [ "$installed" = "$target_version" ] || return 1

        final_commit=$(fetch_package_branch_sha) || return 1
        if [ "$final_commit" = "$PACKAGE_COMMIT" ]; then
            log_ok "OpenClash Dev v$installed 插件包安装完成（提交 $PACKAGE_COMMIT）。"
            return 0
        fi

        log_warn "安装期间官方 package 分支已从 $PACKAGE_COMMIT 更新为 $final_commit，继续安装最新版。"
        install_round=$((install_round + 1))
    done

    return 1
}

extract_version_from_filename() {
    printf '%s\n' "$1" |
        sed -n \
            -e 's/^luci-app-openclash-\([0-9][0-9.]*[0-9]\)\.apk$/\1/p' \
            -e 's/^luci-app-openclash_\([0-9][0-9.]*[0-9]\)_all\.ipk$/\1/p'
}

normalize_version() {
    printf '%s\n' "$1" |
        sed -n 's/^\([0-9][0-9.]*[0-9]\)\(-r[0-9][0-9]*\)\{0,1\}$/\1/p'
}

get_installed_version() {
    if [ "$PKG_MGR" = "opkg" ]; then
        raw_version=$(opkg status luci-app-openclash 2>/dev/null |
            awk -F ': ' '/^Version:/{print $2; exit}')
    else
        raw_version=$(apk list -I luci-app-openclash 2>/dev/null |
            sed -n 's/^luci-app-openclash-\([0-9][0-9.]*\).*/\1/p' |
            head -n 1)
    fi
    normalize_version "$raw_version"
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
        i386 | i486 | i586 | i686) printf '%s\n' "linux-386" ;;
        aarch64 | arm64) printf '%s\n' "linux-arm64" ;;
        armv7l | armv7) printf '%s\n' "linux-armv7" ;;
        armv6l | armv6) printf '%s\n' "linux-armv6" ;;
        armv5tel | armv5) printf '%s\n' "linux-armv5" ;;
        mips64) printf '%s\n' "linux-mips64" ;;
        mips64el) printf '%s\n' "linux-mips64le" ;;
        mips) printf 'linux-mips-%s\n' "$(detect_mips_float)" ;;
        mipsel) printf 'linux-mipsle-%s\n' "$(detect_mips_float)" ;;
        loongarch64) printf 'linux-loong64-%s\n' "$(detect_loongarch_abi)" ;;
        riscv64) printf '%s\n' "linux-riscv64" ;;
        s390x) printf '%s\n' "linux-s390x" ;;
        *) return 1 ;;
    esac
}

get_effective_core_type() {
    smart_enable=$(uci -q get openclash.config.smart_enable)
    core_type=$(uci -q get openclash.config.core_type)
    [ "$smart_enable" = "1" ] && core_type="Smart"
    [ -n "$core_type" ] || core_type="Meta"
    printf '%s\n' "$core_type"
}

core_asset_exists() {
    core_arch=$1
    core_type=$(get_effective_core_type)
    [ "$core_type" = "Smart" ] && core_dir="smart" || core_dir="meta"
    jsdelivr_url="https://testingcf.jsdelivr.net/gh/vernesong/OpenClash@core/dev/${core_dir}/clash-${core_arch}.tar.gz"
    raw_url="https://raw.githubusercontent.com/vernesong/OpenClash/core/dev/${core_dir}/clash-${core_arch}.tar.gz"
    proxy_url="${GH_PROXY_PREFIX}${raw_url}"

    for asset_url in "$jsdelivr_url" "$proxy_url" "$raw_url"; do
        if curl -fsIL --retry 2 --connect-timeout 10 --max-time 30 \
            "$asset_url" >/dev/null 2>&1; then
            return 0
        fi
    done
    return 1
}

configure_core_arch() {
    detected=$(detect_core_arch) || die "无法识别当前 CPU 架构。"
    core_asset_exists "$detected" || die "官方 Dev 仓库中不存在匹配的内核资源：$detected"

    uci set openclash.config.release_branch='dev' || die "无法配置 OpenClash Dev 分支。"
    uci set openclash.config.core_version="$detected" || die "无法写入 core_version。"
    uci commit openclash || die "无法提交内核更新配置。"
    log_ok "Dev 内核架构：$detected"
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
    log_info "即将检查依赖、安装 OpenClash Dev 插件包、更新内核并验证服务启动。"
    init_runtime

    print_step "步骤 1/6: 检查运行环境"
    detect_environment

    print_step "步骤 2/6: 更新软件源并检查依赖"
    install_dependencies
    check_required_commands

    print_step "步骤 3/6: 下载并安装 OpenClash Dev 插件包"
    package_file="$TMP_DIR/openclash.$EXT"
    install_latest_openclash_package "$package_file" ||
        die "无法锁定并安装官方 package 分支的最新 .$EXT 安装包。"

    print_step "步骤 4/6: 配置 Dev 内核架构"
    configure_core_arch

    print_step "步骤 5/6: 更新 OpenClash 内核"
    update_core

    print_step "步骤 6/6: 启动并验证 OpenClash"
    start_openclash

    printf '\n'
    print_line
    printf '%b\n' "${G}[OK] OpenClash Dev 插件包、内核及服务更新完成。${N}"
}

if [ "${OPENCLASH_INSTALLER_LIB_ONLY:-0}" != "1" ]; then
    main "$@"
fi
