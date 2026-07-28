#!/bin/sh

# Shared helpers are populated from install_openclash_dev_update.sh by
# py/sync_installer_common.py. This file remains a standalone public script.

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
JSDELIVR_PACKAGE_PREFIX="https://testingcf.jsdelivr.net/gh/vernesong/OpenClash@"
RAW_PACKAGE_PREFIX="https://raw.githubusercontent.com/vernesong/OpenClash"
GH_PROXY_PREFIX="https://v6.gh-proxy.org/"
PACKAGE_MAX_ROUNDS="${PACKAGE_MAX_ROUNDS:-2}"
PACKAGE_MIN_BYTES="${PACKAGE_MIN_BYTES:-262144}"
PACKAGE_REF_CONNECT_TIMEOUT="${PACKAGE_REF_CONNECT_TIMEOUT:-8}"
PACKAGE_REF_MAX_TIME="${PACKAGE_REF_MAX_TIME:-25}"
OPENCLASH_SHARE_DIR="${OPENCLASH_SHARE_DIR:-/usr/share/openclash}"
OPENCLASH_ETC_DIR="${OPENCLASH_ETC_DIR:-/etc/openclash}"
OPENCLASH_INIT="${OPENCLASH_INIT:-/etc/init.d/openclash}"
OPENCLASH_LOG="${OPENCLASH_LOG:-/tmp/openclash.log}"
OPENCLASH_PRESET="${OPENCLASH_PRESET:-/etc/config/openclash-set}"
OS_RELEASE_FILE="${OS_RELEASE_FILE:-/etc/os-release}"
OPENWRT_RELEASE_FILE="${OPENWRT_RELEASE_FILE:-/etc/openwrt_release}"
PKG_MGR=""
EXT=""
FIREWALL_TYPE=""
DISTRO_ID=""
DEPENDENCIES=""
TMP_DIR=""
LOCK_DIR="${LOCK_DIR:-/tmp/install_openclash_dev.lock}"
FEED_FILE=""
FEED_BACKUP=""
FEED_CHANGED=0
PRESERVED_PACKAGE_PATH=""

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
    printf '%b\n' "${C}#              Custom_OpenClash_Rules Installer                #${N}"
    printf '%b\n' "${C}#     https://github.com/Aethersailor/Custom_OpenClash_Rules   #${N}"
    printf '%b\n' "${C}################################################################${N}"
    printf '%b\n\n' "${W}* OpenClash Dev 插件自有覆盖重装流程${N}"
}

restore_feed() {
    [ "$FEED_CHANGED" -eq 1 ] || return 0
    [ -n "$FEED_FILE" ] && [ -f "$FEED_BACKUP" ] || return 1
    cp -p "$FEED_BACKUP" "$FEED_FILE" || return 1
    FEED_CHANGED=0
    return 0
}

cleanup() {
    status=$?
    trap - EXIT INT TERM HUP
    restore_feed >/dev/null 2>&1 || true
    case "$TMP_DIR" in
        /tmp/openclash-installer.*) rm -rf "$TMP_DIR" ;;
    esac
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
        rm -f "$LOCK_DIR/pid" 2>/dev/null || true
        rmdir "$LOCK_DIR" 2>/dev/null ||
            die "运行锁目录无法安全清理：$LOCK_DIR"
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

detect_distribution() {
    if [ -n "${OPENCLASH_DISTRO_OVERRIDE:-}" ]; then
        release_text=$OPENCLASH_DISTRO_OVERRIDE
    else
        release_text=""
        [ -f "$OS_RELEASE_FILE" ] &&
            release_text="$release_text $(cat "$OS_RELEASE_FILE" 2>/dev/null)"
        [ -f "$OPENWRT_RELEASE_FILE" ] &&
            release_text="$release_text $(cat "$OPENWRT_RELEASE_FILE" 2>/dev/null)"
    fi

    release_lower=$(printf '%s\n' "$release_text" | tr '[:upper:]' '[:lower:]')
    case "$release_lower" in
        *immortalwrt*) DISTRO_ID="immortalwrt" ;;
        *openwrt*) DISTRO_ID="openwrt" ;;
        *) return 1 ;;
    esac
}

detect_environment() {
    detect_distribution || die "无法识别 OpenWrt 或 ImmortalWrt 发行版。"

    if command -v opkg >/dev/null 2>&1; then
        PKG_MGR="opkg"
        EXT="ipk"
    elif command -v apk >/dev/null 2>&1; then
        PKG_MGR="apk"
        EXT="apk"
    else
        die "未检测到支持的包管理器（opkg/apk）。"
    fi

    base_dependencies="bash dnsmasq-full curl ca-bundle ip-full ruby ruby-yaml kmod-tun unzip kmod-inet-diag luci-compat luci luci-base"
    if command -v fw4 >/dev/null 2>&1 || command -v nft >/dev/null 2>&1; then
        FIREWALL_TYPE="nftables"
        DEPENDENCIES="$base_dependencies kmod-nft-tproxy"
    elif command -v fw3 >/dev/null 2>&1 || command -v iptables >/dev/null 2>&1; then
        FIREWALL_TYPE="iptables"
        DEPENDENCIES="$base_dependencies iptables ipset iptables-mod-tproxy iptables-mod-extra"
    else
        die "未检测到支持的防火墙架构（fw4/nftables 或 fw3/iptables）。"
    fi

    log_ok "发行版：$DISTRO_ID"
    log_ok "包管理器：$PKG_MGR"
    log_ok "防火墙：$FIREWALL_TYPE"
}

select_feed_file() {
    [ -n "$FEED_FILE" ] && return 0
    if [ "$PKG_MGR" = "opkg" ]; then
        FEED_FILE="/etc/opkg/distfeeds.conf"
    else
        FEED_FILE="/etc/apk/repositories.d/distfeeds.list"
    fi
}

rewrite_feed_to_mirror() {
    source_file=$1
    target_file=$2

    case "$DISTRO_ID" in
        immortalwrt)
            if ! grep -Fq 'https://downloads.immortalwrt.org' "$source_file" &&
                ! grep -Fq 'https://mirrors.vsean.net/openwrt' "$source_file" &&
                ! grep -Fq 'https://mirror.nju.edu.cn/immortalwrt' "$source_file"; then
                return 1
            fi
            sed \
                -e 's,https://downloads\.immortalwrt\.org,https://mirror.nju.edu.cn/immortalwrt,g' \
                -e 's,https://mirrors\.vsean\.net/openwrt,https://mirror.nju.edu.cn/immortalwrt,g' \
                "$source_file" >"$target_file"
            ;;
        openwrt)
            if ! grep -Fq 'https://downloads.openwrt.org' "$source_file" &&
                ! grep -Fq 'https://mirrors.ustc.edu.cn/openwrt' "$source_file"; then
                return 1
            fi
            sed \
                -e 's,https://downloads\.openwrt\.org,https://mirrors.ustc.edu.cn/openwrt,g' \
                "$source_file" >"$target_file"
            ;;
        *)
            return 1
            ;;
    esac
}

prepare_temporary_feed() {
    select_feed_file
    [ -f "$FEED_FILE" ] || return 1

    FEED_BACKUP="$TMP_DIR/distfeeds.original"
    feed_candidate="$TMP_DIR/distfeeds.mirror"
    cp -p "$FEED_FILE" "$FEED_BACKUP" || return 1
    rewrite_feed_to_mirror "$FEED_BACKUP" "$feed_candidate" || return 1

    if cmp -s "$FEED_BACKUP" "$feed_candidate"; then
        log_info "当前 feed 已使用目标发行版镜像。"
        return 0
    fi

    FEED_CHANGED=1
    cp "$feed_candidate" "$FEED_FILE" || {
        restore_feed >/dev/null 2>&1 || true
        return 1
    }
    log_ok "依赖安装 feed 已临时切换到 $DISTRO_ID 对应镜像。"
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

install_dependencies() {
    log_info "备份 feed，并在更新索引前直接切换到指定镜像..."
    prepare_temporary_feed || {
        restore_feed >/dev/null 2>&1 || true
        return 1
    }

    if ! package_update || ! package_install_dependencies; then
        restore_feed >/dev/null 2>&1 || true
        return 1
    fi

    restore_feed || return 1
    log_ok "依赖安装完成，原始 feed 已完整恢复。"
}

check_required_commands() {
    missing=""
    for cmd in awk sed grep curl wc df mktemp uci cp cmp tr; do
        command -v "$cmd" >/dev/null 2>&1 || missing="$missing $cmd"
    done
    [ -z "$missing" ] || die "缺少必要命令：$missing"
}

curl_download() {
    output=$1
    url=$2
    rm -f "$output"
    curl -fsSL --retry 2 --retry-delay 1 \
        --connect-timeout 10 --max-time 180 \
        -o "$output" "$url" &&
        [ -s "$output" ]
}

fetch_package_refs_route() {
    route=$1
    output=$2
    case "$route" in
        direct) url=$GIT_REFS_URL ;;
        proxy) url="${GH_PROXY_PREFIX}${GIT_REFS_URL}" ;;
        *) return 1 ;;
    esac

    rm -f "$output"
    curl -fsSL --connect-timeout "$PACKAGE_REF_CONNECT_TIMEOUT" \
        --max-time "$PACKAGE_REF_MAX_TIME" \
        -H 'Cache-Control: no-cache' -H 'Pragma: no-cache' \
        -o "$output" "$url" 2>/dev/null || return 1
    grep -aq '# service=git-upload-pack' "$output"
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
            log_info "探测官方 package 分支：$route" >&2
            if fetch_package_refs_route "$route" "$refs_file"; then
                selected_route=$route
                printf '%s\n' "$route" >"$route_file"
                break
            fi
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

parse_package_version() {
    sed -n \
        '1s/^v\([0-9][0-9]*\(\.[0-9][0-9]*\)\{1,\}\)\r*$/\1/p' \
        "$1"
}

package_file_name() {
    version=$1
    case "$EXT" in
        ipk) printf 'luci-app-openclash_%s_all.ipk\n' "$version" ;;
        apk) printf 'luci-app-openclash-%s.apk\n' "$version" ;;
        *) return 1 ;;
    esac
}

apk_supports_allow_downgrade() {
    apk add --help 2>&1 | grep -q -- '--allow-downgrade'
}

verify_package_file() {
    file=$1
    [ -s "$file" ] || return 1
    actual_size=$(wc -c <"$file" 2>/dev/null | tr -d ' ')
    [ -n "$actual_size" ] && [ "$actual_size" -ge "$PACKAGE_MIN_BYTES" ] ||
        return 1

    if [ "$PKG_MGR" = "opkg" ]; then
        opkg --noaction install "$file" >/dev/null 2>&1
    elif apk_supports_allow_downgrade; then
        apk add -s --force-reinstall --force-overwrite --clean-protected \
            --allow-untrusted --allow-downgrade "$file" >/dev/null 2>&1
    else
        apk add -s --force-reinstall --force-overwrite --clean-protected \
            --allow-untrusted "$file" >/dev/null 2>&1
    fi
}

download_openclash_package() {
    commit=$1
    file_name=$2
    output=$3
    raw_url="${RAW_PACKAGE_PREFIX}/${commit}/dev/${file_name}"
    jsdelivr_url="${JSDELIVR_PACKAGE_PREFIX}${commit}/dev/${file_name}"
    proxy_url="${GH_PROXY_PREFIX}${raw_url}"

    log_info "下载顺序：testingcf jsDelivr → v6.gh-proxy → GitHub Raw"
    for source in "$jsdelivr_url" "$proxy_url" "$raw_url"; do
        log_info "尝试下载：$source"
        if curl_download "$output" "$source" &&
            verify_package_file "$output"; then
            log_ok "固定提交安装包下载及 dry-run 校验通过。"
            return 0
        fi
        log_warn "当前路径下载或校验失败，尝试下一路径。"
    done
    rm -f "$output"
    return 1
}

normalize_version() {
    printf '%s\n' "$1" |
        sed -n \
            's/^\([0-9][0-9]*\(\.[0-9][0-9]*\)\{1,\}\)\(-r[0-9][0-9]*\)\{0,1\}$/\1/p'
}

get_installed_version() {
    if [ "$PKG_MGR" = "opkg" ]; then
        raw_version=$(opkg status luci-app-openclash 2>/dev/null |
            awk -F ': ' '/^Version:/{print $2; exit}')
    else
        raw_version=$(apk list -I luci-app-openclash 2>/dev/null |
            sed -n \
                's/^luci-app-openclash-\([0-9][0-9]*\(\.[0-9][0-9]*\)\{1,\}\)\(-r[0-9][0-9]*\)\{0,1\}[[:space:]].*$/\1/p' |
            head -n 1)
    fi
    normalize_version "$raw_version"
}

install_openclash_package() {
    package_file=$1
    if [ "$PKG_MGR" = "opkg" ]; then
        opkg install --force-reinstall "$package_file"
    elif apk_supports_allow_downgrade; then
        apk add --force-reinstall --force-overwrite --clean-protected \
            --allow-untrusted --allow-downgrade "$package_file"
    else
        apk add --force-reinstall --force-overwrite --clean-protected \
            --allow-untrusted "$package_file"
    fi
}

preserve_failed_package() {
    package_file=$1
    [ -s "$package_file" ] || return 1
    package_base=$(basename "$package_file")
    PRESERVED_PACKAGE_PATH="/tmp/${package_base}.failed.$$"
    cp -p "$package_file" "$PRESERVED_PACKAGE_PATH" || return 1

    log_error "安装包已保留：$PRESERVED_PACKAGE_PATH"
    if [ "$PKG_MGR" = "opkg" ]; then
        log_error "可手工执行：opkg install --force-reinstall '$PRESERVED_PACKAGE_PATH'"
    elif apk_supports_allow_downgrade; then
        log_error "可手工执行：apk add --force-reinstall --force-overwrite --clean-protected --allow-untrusted --allow-downgrade '$PRESERVED_PACKAGE_PATH'"
    else
        log_error "可手工执行：apk add --force-reinstall --force-overwrite --clean-protected --allow-untrusted '$PRESERVED_PACKAGE_PATH'"
    fi
}

install_latest_openclash_package() {
    round=1
    while [ "$round" -le "$PACKAGE_MAX_ROUNDS" ]; do
        commit=$(fetch_package_branch_sha) || return 1
        case "$commit" in
            '' | *[!0-9a-f]*) return 1 ;;
        esac
        [ "${#commit}" -eq 40 ] || return 1
        log_info "锁定 OpenClash package 提交：$commit"

        version_file="$TMP_DIR/version.$round"
        download_commit_file "$commit" version "$version_file" || return 1
        target_version=$(parse_package_version "$version_file")
        [ -n "$target_version" ] || return 1
        file_name=$(package_file_name "$target_version") || return 1
        package_file="$TMP_DIR/$file_name"

        download_openclash_package "$commit" "$file_name" "$package_file" ||
            return 1
        if ! install_openclash_package "$package_file"; then
            preserve_failed_package "$package_file" || true
            return 1
        fi

        installed_version=$(get_installed_version)
        if [ "$installed_version" != "$target_version" ]; then
            log_error "安装后版本不一致：目标 $target_version，实际 ${installed_version:-未知}。"
            preserve_failed_package "$package_file" || true
            return 1
        fi

        current_commit=$(fetch_package_branch_sha 2>/dev/null || true)
        if [ -z "$current_commit" ] || [ "$current_commit" = "$commit" ]; then
            log_ok "OpenClash Dev v$target_version 已覆盖重装并确认版本。"
            return 0
        fi

        if [ "$round" -lt "$PACKAGE_MAX_ROUNDS" ]; then
            log_warn "package 分支安装期间已移动到 $current_commit，最多再执行一轮。"
            round=$((round + 1))
            continue
        fi

        log_warn "package 分支再次移动；当前安装仍是提交 $commit 的完整自洽版本。"
        log_ok "OpenClash Dev v$target_version 已覆盖重装并确认版本。"
        return 0
    done
    return 1
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

configure_base_uci() {
    detected_arch=$(detect_core_arch) || return 1
    uci -q batch <<EOF
set openclash.config.release_branch='dev'
set openclash.config.github_address_mod='https://testingcf.jsdelivr.net/'
set openclash.config.core_version='$detected_arch'
set openclash.config.enable='1'
EOF
    uci commit openclash || return 1
    log_ok "基础 UCI 已写入；内核架构：$detected_arch"
}

run_core_update() {
    core_script="$OPENCLASH_SHARE_DIR/openclash_core.sh"
    [ -x "$core_script" ] || return 1
    core_type=$(get_effective_core_type)
    log_info "调用 OpenClash 内置内核流程：$core_type"
    "$core_script" "$core_type" ||
        log_warn "内置内核脚本返回非零；请查看 $OPENCLASH_LOG。"
    log_info "内核实际远端更新结果请查看 $OPENCLASH_LOG。"
}

enable_and_restart_openclash() {
    [ -x "$OPENCLASH_INIT" ] || return 1
    uci set openclash.config.enable='1' || return 1
    uci commit openclash || return 1
    "$OPENCLASH_INIT" enable || return 1
    "$OPENCLASH_INIT" restart || return 1
    log_ok "已启用 OpenClash 开机自启并执行重启命令。"
}

main() {
    logo
    log_info "将覆盖重装 OpenClash Dev 插件，并调用内置内核更新流程。"
    init_runtime

    print_step "步骤 1/4：检测环境并临时切换软件源"
    detect_environment
    install_dependencies || die "镜像索引更新或依赖安装失败；原始 feed 已恢复。"
    check_required_commands

    print_step "步骤 2/4：锁定 package 提交并覆盖重装插件"
    install_latest_openclash_package ||
        die "无法锁定、校验或覆盖重装 OpenClash Dev 插件。"

    print_step "步骤 3/4：写入基础 UCI 并调用内置内核流程"
    configure_base_uci || die "OpenClash 基础 UCI 配置失败。"
    run_core_update || die "OpenClash 内置内核脚本不存在或不可执行。"

    print_step "步骤 4/4：启用并重启 OpenClash"
    enable_and_restart_openclash || die "启用或重启 OpenClash 失败。"

    print_line
    log_ok "OpenClash 插件已由安装脚本完成覆盖重装。"
    log_info "内核及相关资源已调用 OpenClash 内置更新流程。"
    log_info "实际远端资源更新结果请查看 $OPENCLASH_LOG。"
    print_line
}

if [ "${OPENCLASH_INSTALLER_LIB_ONLY:-0}" != "1" ]; then
    main "$@"
fi
