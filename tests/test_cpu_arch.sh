#!/bin/sh
set -eu

script=${1:-shell/check_cpu_version.sh}

assert_arch() {
    expected=$1
    flags=$2
    actual=$(CPU_ARCH_OVERRIDE=x86_64 CPU_FLAGS_OVERRIDE="$flags" sh "$script")
    if [ "$actual" != "$expected" ]; then
        printf 'expected %s, got %s\n' "$expected" "$actual" >&2
        exit 1
    fi
}

v2_flags="cx16 lahf_lm popcnt pni sse4_1 sse4_2 ssse3"
v3_flags="$v2_flags avx avx2 bmi1 bmi2 f16c fma movbe lzcnt"

assert_arch "linux-amd64-v1" "sse2"
assert_arch "linux-amd64-v2" "$v2_flags"
assert_arch "linux-amd64-v3" "$v3_flags"
assert_arch "linux-amd64-v3" "$v3_flags avx512f"

printf '%s\n' "CPU architecture detection tests passed."
