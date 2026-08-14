#!/bin/sh

# Shared helpers are populated from install_openclash_dev_update.sh by
# py/sync_installer_common.py. This file remains a standalone public script.

R=''
G=''
Y=''
B=''
C=''
W=''
N=''
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

INSTALLER_TITLE="OpenClash Dev 插件与内核更新"
INSTALLER_SCOPE="OpenClash 插件和内核"
INSTALLER_SCOPE_EXTRA=""
TOTAL_STEPS=5
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
PACKAGE_EXPECTED_SIZE=""
PACKAGE_EXPECTED_SHA256=""
INSTALLER_LOG="/tmp/openclash-installer.$$.log"
CURRENT_STAGE="启动安装器"
WARNING_COUNT=0
FEED_MIRROR_LABEL=""
FEED_RESTORE_RESULT="本次未修改"
TARGET_VERSION=""
PACKAGE_SOURCE=""
PACKAGE_INTEGRITY="文件大小和安装预检通过"
CORE_TYPE_USED=""
CORE_RESULT="尚未执行"
SERVICE_RESULT="尚未执行"

init_terminal() {
    if [ -t 1 ] && [ "${TERM:-dumb}" != "dumb" ]; then
        R='\033[1;31m'
        G='\033[1;32m'
        Y='\033[1;33m'
        B='\033[1;34m'
        C='\033[1;36m'
        W='\033[1;37m'
        N='\033[0m'
    fi
    if [ -t 1 ]; then
        if command -v clear >/dev/null 2>&1; then
            clear 2>/dev/null || printf '\033[2J\033[H'
        else
            printf '\033[2J\033[H'
        fi
    fi
}

append_log() {
    [ -n "$INSTALLER_LOG" ] && [ -f "$INSTALLER_LOG" ] || return 0
    printf '%s\n' "$1" >>"$INSTALLER_LOG" 2>/dev/null || true
}

print_line() {
    printf '%b\n' "${C}============================================================${N}"
}

print_step() {
    step_number=$1
    CURRENT_STAGE=$2
    printf '\n'
    printf '%b\n' "${C}[$step_number/$TOTAL_STEPS]${N} ${W}$CURRENT_STAGE${N}"
    append_log "[$step_number/$TOTAL_STEPS] $CURRENT_STAGE"
}

ui_field() {
    printf '  %s：%s\n' "$1" "$2"
    append_log "$1：$2"
}

log_info() {
    printf '%b\n' "  ${B}$1${N}"
    append_log "信息：$1"
}

log_warn() {
    WARNING_COUNT=$((WARNING_COUNT + 1))
    printf '%b\n' "  ${Y}[注意]${N} $1"
    append_log "注意：$1"
}

log_error() {
    printf '%b\n' "${R}[失败]${N} $1" >&2
    append_log "失败：$1"
}

log_ok() {
    printf '%b\n' "  ${G}[成功]${N} $1"
    append_log "成功：$1"
}

log_skip() {
    printf '%b\n' "  ${Y}[跳过]${N} $1"
    append_log "跳过：$1"
}

run_logged() {
    if [ -n "$INSTALLER_LOG" ]; then
        printf '\n>>> %s\n' "$*" >>"$INSTALLER_LOG" 2>/dev/null || true
        "$@" >>"$INSTALLER_LOG" 2>&1
    else
        "$@"
    fi
}

show_log_excerpt() {
    [ -s "$INSTALLER_LOG" ] || return 0
    command -v tail >/dev/null 2>&1 || return 0
    printf '\n%s\n' "  最后几条错误信息：" >&2
    tail -n 8 "$INSTALLER_LOG" 2>/dev/null |
        while IFS= read -r line; do
            [ -n "$line" ] && printf '    %s\n' "$line" >&2
        done
}

print_failure_summary() {
    failure_message=$1
    restore_message=$2
    printf '\n' >&2
    print_line >&2
    printf '%b\n' "${R}更新未完成${N}" >&2
    print_line >&2
    printf '  失败阶段：%s\n' "$CURRENT_STAGE" >&2
    printf '  失败原因：%s\n' "$failure_message" >&2
    printf '  软件源恢复：%s\n' "$restore_message" >&2
    show_log_excerpt
    printf '\n  建议：检查网络后重新运行同一条安装命令。\n' >&2
    printf '  运行日志：%s\n' "$INSTALLER_LOG" >&2
    print_line >&2
}

die() {
    failure_message=$1
    restore_message=$FEED_RESTORE_RESULT
    if [ "$FEED_CHANGED" -eq 1 ]; then
        if restore_feed >/dev/null 2>&1; then
            restore_message=$FEED_RESTORE_RESULT
        else
            restore_message="恢复失败，请检查 $FEED_FILE"
        fi
    fi
    append_log "失败：$failure_message"
    print_failure_summary "$failure_message" "$restore_message"
    exit 1
}

logo() {
    init_terminal
    print_line
    printf '%b\n' "${W} $INSTALLER_TITLE${N}"
    print_line
    printf '  将更新：%s\n' "$INSTALLER_SCOPE"
    [ -z "${INSTALLER_SCOPE_EXTRA:-}" ] ||
        printf '          %s\n' "$INSTALLER_SCOPE_EXTRA"
    printf '%s\n' '  本次运行会临时切换软件源，结束前自动恢复。'
    printf '%s\n' '  请勿关闭终端。'
}

restore_feed() {
    [ "$FEED_CHANGED" -eq 1 ] || return 0
    [ -n "$FEED_FILE" ] && [ -f "$FEED_BACKUP" ] || return 1
    cp -p "$FEED_BACKUP" "$FEED_FILE" || return 1
    FEED_CHANGED=0
    FEED_RESTORE_RESULT="已恢复为运行前状态"
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
    : >"$INSTALLER_LOG" 2>/dev/null || INSTALLER_LOG=""

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

    case "$DISTRO_ID" in
        immortalwrt) distro_label="ImmortalWrt" ;;
        openwrt) distro_label="OpenWrt" ;;
    esac
    case "$EXT" in
        ipk) package_label="IPK" ;;
        apk) package_label="APK" ;;
    esac
    ui_field "发行版" "$distro_label"
    ui_field "包管理器" "$PKG_MGR"
    ui_field "防火墙" "$FIREWALL_TYPE"
    ui_field "安装包格式" "$package_label"
    log_ok "当前设备环境受支持。"
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
        immortalwrt) mirror_root='https://mirrors.cernet.edu.cn/immortalwrt' ;;
        openwrt) mirror_root='https://cernet.mirrors.ustc.edu.cn/openwrt' ;;
        *)
            return 1
            ;;
    esac

    awk -v mirror_root="$mirror_root" '
        /^[[:space:]]*($|#)/ {
            print
            next
        }
        {
            url_start = match($0, /https?:\/\//)
            if (!url_start) next

            url = substr($0, url_start)
            path_start = index(url, "/releases/")
            snapshot_start = index(url, "/snapshots/")
            if (!path_start || (snapshot_start && snapshot_start < path_start)) {
                path_start = snapshot_start
            }
            if (!path_start) next

            print substr($0, 1, url_start - 1) mirror_root substr(url, path_start)
            rewritten++
        }
        END {
            if (!rewritten) exit 1
        }
    ' "$source_file" >"$target_file"
}

prepare_temporary_feed() {
    select_feed_file
    [ -f "$FEED_FILE" ] || return 1

    FEED_BACKUP="$TMP_DIR/distfeeds.original"
    feed_candidate="$TMP_DIR/distfeeds.mirror"
    cp -p "$FEED_FILE" "$FEED_BACKUP" || return 1
    rewrite_feed_to_mirror "$FEED_BACKUP" "$feed_candidate" || return 1

    case "$DISTRO_ID" in
        immortalwrt) FEED_MIRROR_LABEL="CERNET ImmortalWrt 镜像" ;;
        openwrt) FEED_MIRROR_LABEL="CERNET OpenWrt 镜像" ;;
    esac

    if cmp -s "$FEED_BACKUP" "$feed_candidate"; then
        FEED_RESTORE_RESULT="原软件源无需修改"
        ui_field "软件源" "当前已使用 $FEED_MIRROR_LABEL"
        return 0
    fi

    FEED_CHANGED=1
    FEED_RESTORE_RESULT="等待阶段结束时恢复"
    cp "$feed_candidate" "$FEED_FILE" || {
        restore_feed >/dev/null 2>&1 || true
        return 1
    }
    ui_field "临时镜像" "$FEED_MIRROR_LABEL"
    log_info "原软件源已备份，将在本阶段结束前恢复。"
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
    prepare_temporary_feed || {
        restore_feed >/dev/null 2>&1 || true
        return 1
    }

    log_info "正在更新软件索引并检查 OpenClash 运行依赖……"
    if ! run_logged package_update ||
        ! run_logged package_install_dependencies; then
        restore_feed >/dev/null 2>&1 || true
        return 1
    fi

    restore_feed || return 1
    set -f
    # Intentional split: dependency names are stored as a whitespace list.
    # shellcheck disable=SC2086
    set -- $DEPENDENCIES
    set +f
    dependency_count=$#
    ui_field "软件索引" "更新完成"
    ui_field "运行依赖" "$dependency_count 项依赖检查并安装完成"
    ui_field "原软件源" "$FEED_RESTORE_RESULT"
    log_ok "OpenClash 运行环境已准备完成。"
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
    run_logged curl -fsSL --retry 2 --retry-delay 1 \
        --connect-timeout 10 --max-time 180 \
        -o "$output" "$url" &&
        [ -s "$output" ]
}

file_size_bytes() {
    wc -c <"$1" 2>/dev/null | tr -d ' '
}

file_sha256() {
    file=$1
    digest=""
    if command -v sha256sum >/dev/null 2>&1; then
        digest=$(sha256sum "$file" 2>/dev/null | awk '{print tolower($1)}')
    elif command -v openssl >/dev/null 2>&1; then
        digest=$(openssl dgst -sha256 "$file" 2>/dev/null |
            awk '{print tolower($NF)}')
    else
        return 1
    fi

    case "$digest" in
        *[!0-9a-f]* | '') return 1 ;;
    esac
    [ "${#digest}" -eq 64 ] || return 1
    printf '%s\n' "$digest"
}

base64_sha256_to_hex() {
    command -v base64 >/dev/null 2>&1 || return 1
    command -v od >/dev/null 2>&1 || return 1
    digest=$(printf '%s' "$1" | base64 -d 2>/dev/null |
        od -An -tx1 2>/dev/null | tr -d ' \n')
    case "$digest" in
        *[!0-9a-f]* | '') return 1 ;;
    esac
    [ "${#digest}" -eq 64 ] || return 1
    printf '%s\n' "$digest"
}

parse_jsdelivr_package_metadata() {
    metadata_file=$1
    file_name=$2
    tr -d '\r\n\t ' <"$metadata_file" 2>/dev/null |
        awk -v target="/dev/$file_name" '
            {
                key="\"name\":\"" target "\""
                start=index($0, key)
                if (!start) exit
                tail=substr($0, start)
                remainder=substr(tail, length(key) + 1)
                next_name=index(remainder, "\"name\":\"")
                if (next_name) tail=substr(tail, 1, length(key) + next_name - 1)

                hash_marker="\"hash\":\""
                hash_start=index(tail, hash_marker)
                if (!hash_start) exit
                hash_tail=substr(tail, hash_start + length(hash_marker))
                hash_end=index(hash_tail, "\"")
                if (!hash_end) exit
                hash=substr(hash_tail, 1, hash_end - 1)

                size_marker="\"size\":"
                size_start=index(tail, size_marker)
                if (!size_start) exit
                size=substr(tail, size_start + length(size_marker))
                sub(/[^0-9].*/, "", size)
                if (size ~ /^[0-9]+$/ && size > 0) print hash, size
            }
        '
}

fetch_package_integrity_metadata() {
    commit=$1
    file_name=$2
    PACKAGE_EXPECTED_SIZE=""
    PACKAGE_EXPECTED_SHA256=""
    PACKAGE_INTEGRITY="文件大小和安装预检通过"
    metadata_file="$TMP_DIR/package-metadata.json"
    metadata_url="https://data.jsdelivr.com/v1/package/gh/vernesong/OpenClash@${commit}/flat"

    rm -f "$metadata_file"
    if ! curl -fsSL --connect-timeout "${INTEGRITY_CONNECT_TIMEOUT:-3}" \
        --max-time "${INTEGRITY_MAX_TIME:-8}" \
        -H 'Accept: application/json' \
        -o "$metadata_file" "$metadata_url" 2>/dev/null; then
        append_log "安装包官方元数据不可用，使用文件大小和安装预检。"
        return 0
    fi

    metadata=$(parse_jsdelivr_package_metadata "$metadata_file" "$file_name")
    encoded_hash=${metadata%% *}
    expected_size=${metadata#* }
    if [ -z "$metadata" ] || [ "$expected_size" = "$metadata" ]; then
        append_log "安装包官方元数据不可解析，使用文件大小和安装预检。"
        return 0
    fi

    PACKAGE_EXPECTED_SIZE=$expected_size
    if PACKAGE_EXPECTED_SHA256=$(base64_sha256_to_hex "$encoded_hash"); then
        PACKAGE_INTEGRITY="官方文件大小、SHA-256 和安装预检均通过"
    else
        PACKAGE_EXPECTED_SHA256=""
        PACKAGE_INTEGRITY="官方文件大小和安装预检通过"
    fi
    return 0
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
            append_log "探测官方 package 分支：$route"
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
    actual_size=$(file_size_bytes "$file")
    if [ -n "${PACKAGE_EXPECTED_SIZE:-}" ]; then
        if [ "$actual_size" != "$PACKAGE_EXPECTED_SIZE" ]; then
            log_warn "安装包大小与固定提交元数据不一致。"
            return 1
        fi
    elif [ -z "$actual_size" ] || [ "$actual_size" -lt "$PACKAGE_MIN_BYTES" ]; then
        return 1
    fi

    if [ -n "${PACKAGE_EXPECTED_SHA256:-}" ]; then
        if actual_sha256=$(file_sha256 "$file"); then
            if [ "$actual_sha256" != "$PACKAGE_EXPECTED_SHA256" ]; then
                log_warn "安装包 SHA-256 与固定提交元数据不一致。"
                return 1
            fi
        else
            log_info "设备缺少可用 SHA-256 工具，继续执行包管理器 dry-run 校验。"
            PACKAGE_INTEGRITY="官方文件大小和安装预检通过；设备未提供 SHA-256 工具"
        fi
    fi

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

    fetch_package_integrity_metadata "$commit" "$file_name"
    attempt=1
    for source_name in jsdelivr proxy raw; do
        case "$source_name" in
            jsdelivr)
                source=$jsdelivr_url
                source_label="jsDelivr"
                ;;
            proxy)
                source=$proxy_url
                source_label="v6.gh-proxy"
                ;;
            raw)
                source=$raw_url
                source_label="GitHub Raw"
                ;;
        esac
        log_info "正在通过 $source_label 获取安装包……"
        append_log "下载地址：$source"
        if curl_download "$output" "$source" &&
            verify_package_file "$output"; then
            PACKAGE_SOURCE=$source_label
            return 0
        fi
        if [ "$attempt" -lt 3 ]; then
            log_warn "$source_label 未获得有效安装包，正在自动尝试备用来源。"
        else
            log_warn "$source_label 未获得有效安装包。"
        fi
        attempt=$((attempt + 1))
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
        short_commit=$(printf '%.8s' "$commit")
        ui_field "官方分支" "package"
        ui_field "固定提交" "$short_commit（保证本次下载内容一致）"

        version_file="$TMP_DIR/version.$round"
        download_commit_file "$commit" version "$version_file" || return 1
        target_version=$(parse_package_version "$version_file")
        [ -n "$target_version" ] || return 1
        TARGET_VERSION=$target_version
        file_name=$(package_file_name "$target_version") || return 1
        package_file="$TMP_DIR/$file_name"
        ui_field "目标版本" "$target_version"
        ui_field "安装包" "$file_name"

        download_openclash_package "$commit" "$file_name" "$package_file" ||
            return 1
        ui_field "下载来源" "$PACKAGE_SOURCE"
        ui_field "完整性检查" "$PACKAGE_INTEGRITY"
        ui_field "安装方式" "覆盖安装，包括相同版本"
        if ! run_logged install_openclash_package "$package_file"; then
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
            log_ok "OpenClash $target_version 已安装并完成版本确认。"
            return 0
        fi

        if [ "$round" -lt "$PACKAGE_MAX_ROUNDS" ]; then
            log_warn "package 分支安装期间已移动到 $current_commit，最多再执行一轮。"
            round=$((round + 1))
            continue
        fi

        log_warn "package 分支再次移动；当前安装仍是提交 $commit 的完整自洽版本。"
        log_ok "OpenClash $target_version 已安装并完成版本确认。"
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
    ui_field "CPU / 内核架构" "$detected_arch"
    ui_field "插件分支" "Dev"
    ui_field "下载加速" "testingcf.jsdelivr.net"
    log_ok "内核架构、插件分支和启用状态已写入。"
}

run_core_update() {
    core_script="$OPENCLASH_SHARE_DIR/openclash_core.sh"
    [ -x "$core_script" ] || return 1
    core_type=$(get_effective_core_type)
    CORE_TYPE_USED=$core_type
    ui_field "内核类型" "$core_type"
    log_info "正在调用 OpenClash 内置内核更新流程……"
    if run_logged "$core_script" "$core_type"; then
        CORE_RESULT="内置更新流程已执行"
        log_ok "内核更新流程已交由 OpenClash 处理。"
    else
        CORE_RESULT="内置流程返回警告"
        log_warn "内核内置流程返回非零；详细结果请查看 $OPENCLASH_LOG。"
    fi
    ui_field "结果说明" "下载、解压和替换结果由 OpenClash 自身记录"
}

enable_and_restart_openclash() {
    [ -x "$OPENCLASH_INIT" ] || return 1
    uci set openclash.config.enable='1' || return 1
    uci commit openclash || return 1
    run_logged "$OPENCLASH_INIT" enable || return 1
    run_logged "$OPENCLASH_INIT" restart || return 1
    SERVICE_RESULT="已启用并执行重启"
    ui_field "开机自启" "已启用"
    ui_field "配置状态" "enable=1"
    ui_field "服务操作" "已执行重启"
    log_ok "OpenClash 启用和重启命令执行完成。"
}

print_final_summary() {
    printf '\n'
    print_line
    printf '%b\n' "${G}更新完成${N}"
    print_line
    ui_field "OpenClash 插件" "$TARGET_VERSION，安装并验证成功"
    ui_field "软件源" "$FEED_RESTORE_RESULT"
    ui_field "内核" "$CORE_TYPE_USED，$CORE_RESULT"
    ui_field "OpenClash 服务" "$SERVICE_RESULT"
    ui_field "警告" "$WARNING_COUNT"
    printf '\n'
    ui_field "OpenClash 详细日志" "$OPENCLASH_LOG"
    ui_field "本次运行日志" "$INSTALLER_LOG"
    print_line
}

main() {
    logo
    init_runtime

    print_step 1 "检测设备环境"
    detect_environment

    print_step 2 "准备软件源和运行依赖"
    install_dependencies || die "软件索引更新或依赖安装失败。"
    check_required_commands

    print_step 3 "获取并安装 OpenClash 插件"
    install_latest_openclash_package ||
        die "无法锁定、校验或覆盖重装 OpenClash Dev 插件。"

    print_step 4 "配置并更新 OpenClash 内核"
    configure_base_uci || die "OpenClash 基础 UCI 配置失败。"
    run_core_update || die "OpenClash 内置内核脚本不存在或不可执行。"

    print_step 5 "启用并重启 OpenClash"
    enable_and_restart_openclash || die "启用或重启 OpenClash 失败。"

    print_final_summary
}

if [ "${OPENCLASH_INSTALLER_LIB_ONLY:-0}" != "1" ]; then
    main "$@"
fi
