#!/bin/sh

# 检测 MIPS 浮点类型
detect_mips_float() {
    # 检查是否有硬件 FPU
    if grep -q "FPU.*yes" /proc/cpuinfo 2>/dev/null; then
        echo "hardfloat"
    else
        echo "softfloat"
    fi
}

# 检测 LoongArch ABI 版本
detect_loongarch_abi() {
    # 检查内核版本和 ABI 信息
    # abi2 是较新的 ABI，通常在 5.19+ 内核中使用
    kernel_ver=$(uname -r | cut -d. -f1,2)
    major=$(echo "$kernel_ver" | cut -d. -f1)
    minor=$(echo "$kernel_ver" | cut -d. -f2)
    
    # 5.19 及以上默认使用 abi2
    if [ "$major" -gt 5 ] || ([ "$major" -eq 5 ] && [ "$minor" -ge 19 ]); then
        echo "abi2"
    else
        echo "abi1"
    fi
}

# 架构名称映射函数（返回完整的 linux-{arch} 格式）
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
    # 非 x86 架构,输出 linux-{arch} 格式
    map_arch "$arch"
    exit 0
fi

# x86_64 架构,读取 CPU flags
flags=$(grep -m1 -o -E 'flags\s*:.*' /proc/cpuinfo | cut -d: -f2)

# 判断 v4 (AVX512)
if echo "$flags" | grep -qE 'avx512f'; then
    echo "linux-amd64-v4"
    exit 0
fi

# 判断 v3 (AVX/AVX2 等)
if echo "$flags" | grep -qE 'avx'; then
    if echo "$flags" | grep -qE 'avx2' && \
       echo "$flags" | grep -qE 'bmi1' && \
       echo "$flags" | grep -qE 'bmi2'; then
        echo "linux-amd64-v3"
        exit 0
    fi
fi

# 判断 v2 (SSE4.2 / SSE3 / POPCNT 等)
if echo "$flags" | grep -qE 'sse4_2' && \
   echo "$flags" | grep -qE 'sse4_1' && \
   echo "$flags" | grep -qE 'ssse3' && \
   echo "$flags" | grep -qE 'sse3' && \
   echo "$flags" | grep -qE 'popcnt'; then
    echo "linux-amd64-v2"
    exit 0
fi

# 默认 v1
echo "linux-amd64-v1"
exit 0
