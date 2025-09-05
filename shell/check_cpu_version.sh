#!/bin/sh

# 判断 CPU 架构
arch=$(uname -m)
if [ "$arch" != "x86_64" ]; then
    echo "非 x86 架构，无法判断 GOAMD64 等级"
    exit 0
fi

# 读取 CPU flags
flags=$(grep -m1 -o -E 'flags\s*:.*' /proc/cpuinfo | cut -d: -f2)

# 判断 v4 (AVX512)
if echo "$flags" | grep -qE 'avx512f'; then
    echo "GOAMD64=v4"
    exit 0
fi

# 判断 v3 (AVX/AVX2 等)
if echo "$flags" | grep -qE 'avx'; then
    if echo "$flags" | grep -qE 'avx2' && \
       echo "$flags" | grep -qE 'bmi1' && \
       echo "$flags" | grep -qE 'bmi2'; then
        echo "GOAMD64=v3"
        exit 0
    fi
fi

# 判断 v2 (SSE4.2 / SSE3 / POPCNT 等)
if echo "$flags" | grep -qE 'sse4_2' && \
   echo "$flags" | grep -qE 'sse4_1' && \
   echo "$flags" | grep -qE 'ssse3' && \
   echo "$flags" | grep -qE 'sse3' && \
   echo "$flags" | grep -qE 'popcnt'; then
    echo "GOAMD64=v2"
    exit 0
fi

# 默认 v1
echo "GOAMD64=v1"
exit 0
