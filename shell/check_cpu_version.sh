#!/bin/sh

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

has_cpu_flag() {
    flag=$1
    printf ' %s ' "$CPU_FLAGS" | grep -q " $flag "
}

has_all_cpu_flags() {
    for flag in "$@"; do
        has_cpu_flag "$flag" || return 1
    done
}

detect_amd64_level() {
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
}

map_arch() {
    arch=$1

    case "$arch" in
        x86_64) detect_amd64_level ;;
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
        *)
            printf 'unsupported architecture: %s\n' "$arch" >&2
            return 1
            ;;
    esac
}

map_arch "${CPU_ARCH_OVERRIDE:-$(uname -m)}"
