#!/bin/sh

# 架构名称映射函数
map_arch() {
    case "$1" in
        x86_64)
            echo "amd64"
            ;;
        i386|i686)
            echo "386"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        armv7l|armv7)
            echo "armv7"
            ;;
        armv6l|armv6)
            echo "armv6"
            ;;
        armv5tel|armv5)
            echo "armv5"
            ;;
        mips64)
            echo "mips64"
            ;;
        mips64el)
            echo "mips64le"
            ;;
        mips)
            echo "mips"
            ;;
        mipsel)
            echo "mipsle"
            ;;
        loongarch64)
            echo "loong64"
            ;;
        riscv64)
            echo "riscv64"
            ;;
        s390x)
            echo "s390x"
            ;;
        *)
            echo "$1"
            ;;
    esac
}

# 判断 CPU 架构
arch=$(uname -m)
if [ "$arch" != "x86_64" ]; then
    # 非 x86 架构,输出标准化的架构名
    map_arch "$arch"
    exit 0
fi

# x86_64 架构,读取 CPU flags
flags=$(grep -m1 -o -E 'flags\s*:.*' /proc/cpuinfo | cut -d: -f2)

# 判断 v4 (AVX512)
if echo "$flags" | grep -qE 'avx512f'; then
    echo "amd64-v4"
    exit 0
fi

# 判断 v3 (AVX/AVX2 等)
if echo "$flags" | grep -qE 'avx'; then
    if echo "$flags" | grep -qE 'avx2' && \
       echo "$flags" | grep -qE 'bmi1' && \
       echo "$flags" | grep -qE 'bmi2'; then
        echo "amd64-v3"
        exit 0
    fi
fi

# 判断 v2 (SSE4.2 / SSE3 / POPCNT 等)
if echo "$flags" | grep -qE 'sse4_2' && \
   echo "$flags" | grep -qE 'sse4_1' && \
   echo "$flags" | grep -qE 'ssse3' && \
   echo "$flags" | grep -qE 'sse3' && \
   echo "$flags" | grep -qE 'popcnt'; then
    echo "amd64-v2"
    exit 0
fi

# 默认 v1
echo "amd64-v1"
exit 0
