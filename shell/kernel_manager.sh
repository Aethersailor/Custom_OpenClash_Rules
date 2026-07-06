#!/usr/bin/env bash

# Debian and Proxmox VE kernel cleanup assistant.
# Safety policy:
#   - Never remove the running kernel.
#   - Only clean when the running kernel is the newest installed kernel.
#   - Remove every older kernel and its version-specific headers.
#   - On PVE, never override an explicit manual selection or kernel pin.
#   - Only purge exact, version-specific package names after a clean APT simulation.
#   - Never remove files from /boot or /lib/modules directly.

set -Eeuo pipefail
IFS=$'\n\t'
export LC_ALL=C

DRY_RUN=0

usage() {
    cat <<'EOF'
用法:
  kernel_manager.sh [--dry-run]

选项:
  --dry-run  只分析并执行 APT 模拟，不进行任何修改
  -h, --help 显示帮助

当前内核为最新内核时，脚本会清理全部旧内核及其对应 headers。
默认模式会先显示完整计划和 APT 模拟结果，然后要求输入 y 才会执行。
脚本不会自动重启，也不会执行不限定范围的 autoremove。
EOF
}

while (($# > 0)); do
    case "$1" in
        --dry-run)
            DRY_RUN=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf '错误: 未知参数: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    printf '错误: 请使用 root 权限运行此脚本。\n' >&2
    exit 1
fi

if [[ -t 1 ]]; then
    readonly GREEN=$'\033[32m'
    readonly YELLOW=$'\033[33m'
    readonly RED=$'\033[31m'
    readonly BLUE=$'\033[34m'
    readonly NC=$'\033[0m'
else
    readonly GREEN=''
    readonly YELLOW=''
    readonly RED=''
    readonly BLUE=''
    readonly NC=''
fi

info() {
    printf '%s%s%s\n' "$BLUE" "$*" "$NC"
}

warn() {
    printf '%s警告: %s%s\n' "$YELLOW" "$*" "$NC" >&2
}

die() {
    printf '%s错误: %s%s\n' "$RED" "$*" "$NC" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "缺少必需命令: $1"
}

for command_name in apt-get apt-mark dpkg dpkg-query find grep rm sort uname; do
    require_command "$command_name"
done

if ((!DRY_RUN)); then
    require_command flock
    exec 9>/run/lock/kernel-manager.lock
    flock -n 9 || die "另一个 kernel_manager 实例正在运行。"
fi

if [[ -n $(dpkg --audit) ]]; then
    dpkg --audit >&2
    die "dpkg 状态不完整，请先修复包管理器状态。"
fi

RUNNING_KERNEL=$(uname -r)
[[ -n $RUNNING_KERNEL ]] || die "无法识别当前运行内核。"

PVE_MODE=0
if [[ $(dpkg-query -W -f='${db:Status-Status}' pve-manager 2>/dev/null || true) == installed ]]; then
    PVE_MODE=1
fi

declare -a INSTALLED_PACKAGES=()
declare -A INSTALLED_ABI_SET=()
declare -A COMPONENT_ABI_SET=()
declare -A IMAGE_PACKAGES_BY_ABI=()
declare -A INSTALLED_PACKAGE_BY_BASE=()
declare -A PROTECTED_ABIS=()
declare -A PROTECTION_REASONS=()
declare -A HELD_PACKAGES=()

add_image_package() {
    local abi=$1
    local package=$2

    INSTALLED_ABI_SET["$abi"]=1
    IMAGE_PACKAGES_BY_ABI["$abi"]="${IMAGE_PACKAGES_BY_ABI[$abi]-}${package}"$'\n'
}

protect_abi() {
    local abi=$1
    local reason=$2

    PROTECTED_ABIS["$abi"]=1
    if [[ -n ${PROTECTION_REASONS[$abi]-} ]]; then
        PROTECTION_REASONS["$abi"]+=", $reason"
    else
        PROTECTION_REASONS["$abi"]=$reason
    fi
}

while IFS=$'\t' read -r package status; do
    [[ $status == installed ]] || continue
    INSTALLED_PACKAGES+=("$package")

    package_without_arch=${package%%:*}
    INSTALLED_PACKAGE_BY_BASE["$package_without_arch"]=$package
    abi=''
    component_abi=''

    if ((PVE_MODE)); then
        if [[ $package_without_arch =~ ^proxmox-kernel-([0-9].*-pve)(-signed)?$ ]]; then
            abi=${BASH_REMATCH[1]}
        elif [[ $package_without_arch =~ ^pve-kernel-([0-9].*-pve)$ ]]; then
            abi=${BASH_REMATCH[1]}
        elif [[ $package_without_arch =~ ^(proxmox-headers|pve-headers)-([0-9].*-pve)$ ]]; then
            component_abi=${BASH_REMATCH[2]}
        fi
    elif [[ $package_without_arch =~ ^linux-image-(unsigned-)?([0-9].*)$ ]]; then
        abi=${BASH_REMATCH[2]}
    elif [[ $package_without_arch =~ ^linux-(base|binary|modules|modules-extra)-([0-9].*)$ ]]; then
        component_abi=${BASH_REMATCH[2]}
    elif [[ $package_without_arch =~ ^linux-headers-([0-9].*)$ ]]; then
        component_abi=${BASH_REMATCH[1]}
        [[ $package_without_arch == *-common ]] && component_abi=''
    fi

    if [[ -n $abi ]]; then
        add_image_package "$abi" "$package"
        COMPONENT_ABI_SET["$abi"]=1
    elif [[ -n $component_abi ]]; then
        COMPONENT_ABI_SET["$component_abi"]=1
    fi
done < <(dpkg-query -W -f='${binary:Package}\t${db:Status-Status}\n')

((${#INSTALLED_ABI_SET[@]} > 0)) || {
    if ((PVE_MODE)); then
        die "未找到已安装的版本化 PVE 内核镜像包。"
    fi
    die "未找到已安装的版本化 Debian 内核镜像包。"
}

mapfile -t INSTALLED_ABIS < <(printf '%s\n' "${!INSTALLED_ABI_SET[@]}" | sort -V)
LATEST_INSTALLED=${INSTALLED_ABIS[-1]}

if ((PVE_MODE)); then
    PLATFORM='Proxmox VE'
else
    PLATFORM='Debian'
fi

printf '%s--- %s 内核安全管理助手 ---%s\n' "$BLUE" "$PLATFORM" "$NC"
printf '当前运行内核: %s%s%s\n' "$GREEN" "$RUNNING_KERNEL" "$NC"
printf '最新已安装内核: %s%s%s\n' "$GREEN" "$LATEST_INSTALLED" "$NC"

[[ -n ${INSTALLED_ABI_SET[$RUNNING_KERNEL]+x} ]] ||
    die "当前运行内核没有对应的已安装镜像包，拒绝继续。"

if [[ $RUNNING_KERNEL != "$LATEST_INSTALLED" ]]; then
    warn "当前运行内核不是最新已安装内核。"
    printf '请先安排维护窗口并手动重启，确认系统正常启动到 %s 后再运行本脚本。\n' \
        "$LATEST_INSTALLED"
    exit 0
fi

protect_abi "$RUNNING_KERNEL" '当前运行'

if ((PVE_MODE)); then
    require_command proxmox-boot-tool
    if ! PVE_KERNEL_LIST=$(proxmox-boot-tool kernel list 2>&1); then
        printf '%s\n' "$PVE_KERNEL_LIST" >&2
        die "无法读取 proxmox-boot-tool 内核保护列表。"
    fi

    pve_kernel_section=''
    while IFS= read -r selected_abi; do
        case "$selected_abi" in
            'Manually selected kernels:')
                pve_kernel_section='manual'
                continue
                ;;
            'Automatically selected kernels:')
                pve_kernel_section='automatic'
                continue
                ;;
            'Pinned kernel:')
                pve_kernel_section='pinned'
                continue
                ;;
            'Kernel pinned on next-boot:')
                pve_kernel_section='next-boot'
                continue
                ;;
        esac

        selected_abi=${selected_abi#"${selected_abi%%[![:space:]]*}"}
        selected_abi=${selected_abi%"${selected_abi##*[![:space:]]}"}
        [[ $selected_abi =~ ^[0-9][0-9A-Za-z.+:~_-]*-pve$ ]] || continue

        if [[ $pve_kernel_section != automatic && $selected_abi != "$RUNNING_KERNEL" ]]; then
            die "旧内核 $selected_abi 已被 PVE 手工选择或固定；请先解除该配置再清理。"
        fi
    done <<<"$PVE_KERNEL_LIST"
fi

while IFS= read -r held_package; do
    [[ -n $held_package ]] || continue
    HELD_PACKAGES["${held_package%%:*}"]=1
done < <(apt-mark showhold)

packages_for_abi() {
    local abi=$1
    local package package_without_arch depends relation dependency
    local -a dependency_relations=()

    printf '%s' "${IMAGE_PACKAGES_BY_ABI[$abi]-}"
    for package in "${INSTALLED_PACKAGES[@]}"; do
        package_without_arch=${package%%:*}
        case "$package_without_arch" in
            "linux-headers-$abi")
                printf '%s\n' "$package"
                depends=$(dpkg-query -W -f='${Depends}' "$package" 2>/dev/null || true)
                IFS=',' read -r -a dependency_relations <<<"$depends"
                for relation in "${dependency_relations[@]}"; do
                    dependency=${relation%%|*}
                    dependency=${dependency#"${dependency%%[![:space:]]*}"}
                    dependency=${dependency%%[[:space:](]*}
                    dependency=${dependency%%:*}
                    if [[ $dependency =~ ^linux-headers-[0-9].*-common$ &&
                        -n ${INSTALLED_PACKAGE_BY_BASE[$dependency]+x} ]]; then
                        printf '%s\n' "${INSTALLED_PACKAGE_BY_BASE[$dependency]}"
                    fi
                done
                ;;
            "linux-base-$abi"|"linux-binary-$abi"|\
            "linux-modules-$abi"|"linux-modules-extra-$abi"|\
            "proxmox-headers-$abi"|"pve-headers-$abi")
                printf '%s\n' "$package"
                ;;
            linux-headers-*-common)
                dependency=${package_without_arch#linux-headers-}
                dependency=${dependency%-common}
                if [[ $abi == "$dependency"-* ]]; then
                    printf '%s\n' "$package"
                fi
                ;;
        esac
    done
}

declare -A CLEANUP_ABI_SET=()
for abi in "${INSTALLED_ABIS[@]}"; do
    [[ $abi == "$RUNNING_KERNEL" ]] || CLEANUP_ABI_SET["$abi"]=1
done
for abi in "${!COMPONENT_ABI_SET[@]}"; do
    if [[ $abi != "$RUNNING_KERNEL" ]] &&
        dpkg --compare-versions "$abi" lt "$RUNNING_KERNEL"; then
        CLEANUP_ABI_SET["$abi"]=1
    fi
done

declare -a CLEANUP_ABIS=()
if ((${#CLEANUP_ABI_SET[@]} > 0)); then
    mapfile -t CLEANUP_ABIS < <(printf '%s\n' "${!CLEANUP_ABI_SET[@]}" | sort -V)
fi

for abi in "${CLEANUP_ABIS[@]}"; do
    while IFS= read -r package; do
        [[ -n $package ]] || continue
        if [[ -n ${HELD_PACKAGES[${package%%:*}]+x} ]]; then
            protect_abi "$abi" "包已 hold: ${package%%:*}"
            warn "旧内核 ABI $abi 包含 hold 软件包，已跳过。"
            break
        fi
    done < <(packages_for_abi "$abi")
done

printf '\n受保护内核:\n'
for abi in "${INSTALLED_ABIS[@]}"; do
    [[ -n ${PROTECTED_ABIS[$abi]+x} ]] || continue
    printf '  - %s (%s)\n' "$abi" "${PROTECTION_REASONS[$abi]}"

    [[ -s /boot/vmlinuz-"$abi" ]] ||
        die "受保护内核缺少 /boot/vmlinuz-$abi，拒绝清理。"
    [[ -s /boot/initrd.img-"$abi" ]] ||
        die "受保护内核缺少 /boot/initrd.img-$abi，拒绝清理。"
done

[[ -d /lib/modules/$RUNNING_KERNEL ]] ||
    die "当前运行内核缺少 /lib/modules/$RUNNING_KERNEL，拒绝清理。"

declare -a CANDIDATE_ABIS=()
for abi in "${CLEANUP_ABIS[@]}"; do
    [[ -n ${PROTECTED_ABIS[$abi]+x} ]] || CANDIDATE_ABIS+=("$abi")
done

if ((${#CANDIDATE_ABIS[@]} == 0)); then
    printf '\n%s没有可安全清理的旧内核。%s\n' "$GREEN" "$NC"
    exit 0
fi

declare -a CANDIDATE_PACKAGES=()
declare -A CANDIDATE_PACKAGE_SET=()

declare -a remaining_boot_files=()
for abi in "${CANDIDATE_ABIS[@]}"; do
    while IFS= read -r package; do
        [[ -n $package ]] || continue
        package_key=${package%%:*}
        if [[ -z ${CANDIDATE_PACKAGE_SET[$package_key]+x} ]]; then
            CANDIDATE_PACKAGES+=("$package")
            CANDIDATE_PACKAGE_SET["$package_key"]=1
        fi
    done < <(packages_for_abi "$abi")
done

((${#CANDIDATE_PACKAGES[@]} > 0)) || die "候选内核没有对应的软件包，拒绝继续。"
mapfile -t CANDIDATE_PACKAGES < <(printf '%s\n' "${CANDIDATE_PACKAGES[@]}" | sort -u)

printf '\n%s计划清理的旧内核 ABI:%s\n' "$YELLOW" "$NC"
printf '  - %s\n' "${CANDIDATE_ABIS[@]}"
printf '\n%s将精确 purge 以下软件包:%s\n' "$YELLOW" "$NC"
printf '  - %s\n' "${CANDIDATE_PACKAGES[@]}"

info '正在执行只读 APT 模拟...'
if ! APT_SIMULATION=$(apt-get -s purge -- "${CANDIDATE_PACKAGES[@]}" 2>&1); then
    printf '%s\n' "$APT_SIMULATION" >&2
    die "APT 模拟失败，未执行任何修改。"
fi
printf '%s\n' "$APT_SIMULATION"

validate_apt_simulation() {
    local simulation=$1
    local action package package_key _rest
    local -A simulated_removals=()
    local -a unexpected_removals=()

    if grep -Eq 'essential packages will be removed|^WARNING:' <<<"$simulation"; then
        die "APT 模拟包含高风险警告，拒绝执行。"
    fi

    while IFS=' ' read -r action package _rest; do
        case "$action" in
            Remv|Purg)
                package_key=${package%%:*}
                simulated_removals["$package_key"]=1
                if [[ -z ${CANDIDATE_PACKAGE_SET[$package_key]+x} ]]; then
                    unexpected_removals+=("$package")
                fi
                ;;
        esac
    done <<<"$simulation"

    if ((${#unexpected_removals[@]} > 0)); then
        printf 'APT 还计划删除以下未授权软件包:\n' >&2
        printf '  - %s\n' "${unexpected_removals[@]}" >&2
        die "APT 模拟超出精确清理范围。"
    fi

    for package in "${CANDIDATE_PACKAGES[@]}"; do
        package_key=${package%%:*}
        [[ -n ${simulated_removals[$package_key]+x} ]] ||
            die "APT 模拟没有包含预期软件包 $package，拒绝执行。"
    done
}

validate_apt_simulation "$APT_SIMULATION"

printf '\n%sAPT 模拟通过：删除集合与授权软件包完全一致。%s\n' "$GREEN" "$NC"

if ((DRY_RUN)); then
    printf '%s--dry-run 已完成，系统未被修改。%s\n' "$GREEN" "$NC"
    exit 0
fi

[[ -r /dev/tty && -w /dev/tty ]] ||
    die "执行模式需要交互式终端；无人值守环境请使用 --dry-run。"

printf '\n%s是否执行以上精确清理？[y/N]: %s' \
    "$RED" "$NC" >/dev/tty
IFS= read -r confirmation </dev/tty || die "无法读取确认输入。"
if [[ ! $confirmation =~ ^[Yy]$ ]]; then
    printf '操作已取消，系统未被修改。\n'
    exit 0
fi

info '正在执行确认后的最终 APT 模拟...'
if ! FINAL_APT_SIMULATION=$(apt-get -s purge -- "${CANDIDATE_PACKAGES[@]}" 2>&1); then
    printf '%s\n' "$FINAL_APT_SIMULATION" >&2
    die "最终 APT 模拟失败，未执行清理。"
fi
validate_apt_simulation "$FINAL_APT_SIMULATION"
[[ $FINAL_APT_SIMULATION == "$APT_SIMULATION" ]] ||
    die "确认期间软件包状态或删除计划发生变化，请重新运行脚本。"

info '正在通过 APT purge 已确认的软件包...'
DEBIAN_FRONTEND=noninteractive apt-get purge -y -- "${CANDIDATE_PACKAGES[@]}"

path_has_installed_owner() {
    local target=$1
    local ownership owners owner owner_status
    local -a owner_list=()

    while IFS= read -r ownership; do
        [[ $ownership == *': '* ]] || continue
        owners=${ownership%%: *}
        IFS=',' read -r -a owner_list <<<"$owners"
        for owner in "${owner_list[@]}"; do
            owner=${owner#"${owner%%[![:space:]]*}"}
            owner=${owner%"${owner##*[![:space:]]}"}
            owner_status=$(dpkg-query -W -f='${db:Status-Status}' "$owner" 2>/dev/null || true)
            [[ $owner_status == installed ]] && return 0
        done
    done < <(dpkg-query -S "$target" 2>/dev/null || true)

    return 1
}

list_existing_boot_residues() {
    local abi=$1
    local target
    local -a candidates=()

    shopt -s nullglob
    candidates=(
        /boot/config-"$abi" /boot/config-"$abi".*
        /boot/initrd.img-"$abi" /boot/initrd.img-"$abi".*
        /boot/System.map-"$abi" /boot/System.map-"$abi".*
        /boot/symvers-"$abi" /boot/symvers-"$abi".*
        /boot/vmlinuz-"$abi" /boot/vmlinuz-"$abi".*
    )
    shopt -u nullglob

    for target in "${candidates[@]}"; do
        [[ -e $target || -L $target ]] && printf '%s\0' "$target"
    done
}

cleanup_abi_residues() {
    local abi=$1
    local target module_dir
    local -a boot_residues=()

    [[ $abi != "$RUNNING_KERNEL" ]] ||
        die "内部安全检查失败：拒绝清理当前内核 $abi。"
    [[ -n ${CLEANUP_ABI_SET[$abi]+x} ]] ||
        die "内部安全检查失败：$abi 不在旧内核集合中。"

    while IFS= read -r -d '' target; do
        boot_residues+=("$target")
    done < <(list_existing_boot_residues "$abi")

    for target in "${boot_residues[@]}"; do
        [[ -e $target || -L $target ]] || continue
        [[ -f $target || -L $target ]] ||
            die "拒绝删除非普通文件残留: $target"
        path_has_installed_owner "$target" &&
            die "残留仍由已安装软件包拥有，拒绝删除: $target"
        rm -f -- "$target"
    done

    module_dir=/lib/modules/"$abi"
    if [[ -e $module_dir || -L $module_dir ]]; then
        [[ -d $module_dir && ! -L $module_dir ]] ||
            die "拒绝删除异常模块路径: $module_dir"
        while IFS= read -r -d '' target; do
            path_has_installed_owner "$target" &&
                die "模块残留仍由已安装软件包拥有，拒绝删除: $target"
        done < <(find -P "$module_dir" -xdev -mindepth 1 -print0)
        rm -rf --one-file-system -- "$module_dir"
    fi
}

info '正在清理已确认无软件包归属的旧内核生成残留...'
for abi in "${CANDIDATE_ABIS[@]}"; do
    cleanup_abi_residues "$abi"
done

if ((PVE_MODE)) && [[ -s /etc/kernel/proxmox-boot-uuids ]]; then
    info '正在同步 Proxmox EFI System Partitions...'
    proxmox-boot-tool refresh
fi

if command -v update-grub >/dev/null 2>&1 && [[ -d /boot/grub ]]; then
    info '正在刷新 GRUB 配置...'
    update-grub
fi

[[ -s /boot/vmlinuz-$RUNNING_KERNEL ]] ||
    die "清理后校验失败：当前内核镜像缺失。"
[[ -s /boot/initrd.img-$RUNNING_KERNEL ]] ||
    die "清理后校验失败：当前内核 initrd 缺失。"
[[ -d /lib/modules/$RUNNING_KERNEL ]] ||
    die "清理后校验失败：当前内核模块目录缺失。"

for package in "${CANDIDATE_PACKAGES[@]}"; do
    status=$(dpkg-query -W -f='${db:Status-Status}' "$package" 2>/dev/null || true)
    [[ $status != installed ]] || die "清理后校验失败：$package 仍处于已安装状态。"
done

if [[ -n $(dpkg --audit) ]]; then
    dpkg --audit >&2
    die "清理后 dpkg 审计发现异常，请立即检查包管理器状态。"
fi

for abi in "${CANDIDATE_ABIS[@]}"; do
    remaining_boot_files=()
    while IFS= read -r -d '' target; do
        remaining_boot_files+=("$target")
    done < <(list_existing_boot_residues "$abi")
    ((${#remaining_boot_files[@]} == 0)) ||
        die "清理后校验失败：/boot 中仍有 $abi 残留。"
    [[ ! -e /lib/modules/$abi && ! -L /lib/modules/$abi ]] ||
        die "清理后校验失败：/lib/modules/$abi 仍然存在。"
done

printf '\n%s旧内核、对应 headers 及生成残留已完整清理并通过校验。%s\n' \
    "$GREEN" "$NC"
printf '为避免扩大删除范围，本脚本未执行 apt autoremove。\n'
