#!/bin/sh

set -u

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
INSTALLER="$SCRIPT_DIR/../install_openclash_dev_update.sh"
OPENCLASH_INSTALLER_LIB_ONLY=1
export OPENCLASH_INSTALLER_LIB_ONLY
# shellcheck source=../install_openclash_dev_update.sh
# shellcheck disable=SC1091
. "$INSTALLER"

TEST_TMP=$(mktemp -d "${TMPDIR:-/tmp}/openclash-installer-tests.XXXXXX")
trap 'rm -rf "$TEST_TMP"' EXIT INT TERM HUP

PASS=0
FAIL=0

pass() {
    PASS=$((PASS + 1))
    printf 'ok %d - %s\n' "$PASS" "$1"
}

fail() {
    FAIL=$((FAIL + 1))
    printf 'not ok - %s\n' "$1" >&2
}

assert_eq() {
    expected=$1
    actual=$2
    name=$3
    if [ "$expected" = "$actual" ]; then
        pass "$name"
    else
        fail "$name (expected: $expected, actual: $actual)"
    fi
}

assert_true() {
    name=$1
    shift
    if "$@"; then
        pass "$name"
    else
        fail "$name"
    fi
}

assert_false() {
    name=$1
    shift
    if "$@"; then
        fail "$name"
    else
        pass "$name"
    fi
}

cat >"$TEST_TMP/package.json" <<'EOF'
[
  {
    "name": "luci-app-openclash-0.47.099.apk",
    "path": "dev/luci-app-openclash-0.47.099.apk",
    "sha": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    "size": 12345,
    "download_url": "https://example.invalid/openclash.apk"
  },
  {
    "name": "luci-app-openclash_0.47.099_all.ipk",
    "path": "dev/luci-app-openclash_0.47.099_all.ipk",
    "sha": "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
    "size": 23456,
    "download_url": "https://example.invalid/openclash.ipk"
  }
]
EOF

EXT=apk
export EXT
assert_eq \
    "luci-app-openclash-0.47.099.apk|aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa|12345" \
    "$(parse_package_metadata "$TEST_TMP/package.json")" \
    "parse APK metadata"

EXT=ipk
export EXT
assert_eq \
    "luci-app-openclash_0.47.099_all.ipk|bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb|23456" \
    "$(parse_package_metadata "$TEST_TMP/package.json")" \
    "parse IPK metadata"

assert_eq "0.47.099" \
    "$(extract_version_from_filename luci-app-openclash-0.47.099.apk)" \
    "extract APK version"
assert_eq "0.47.099" \
    "$(extract_version_from_filename luci-app-openclash_0.47.099_all.ipk)" \
    "extract IPK version"
assert_eq "" \
    "$(extract_version_from_filename luci-app-openclash-latest.apk)" \
    "reject malformed package version"
assert_eq "0.47.099" \
    "$(normalize_version 0.47.099)" \
    "normalize plain installed version"
assert_eq "0.47.099" \
    "$(normalize_version 0.47.099-r1)" \
    "strip OPKG package revision"
assert_eq "" \
    "$(normalize_version 0.47.099-custom)" \
    "reject unsupported installed version suffix"

test_temporary_mirror_roundtrip() (
    TMP_DIR="$TEST_TMP/mirror"
    mkdir -p "$TMP_DIR"
    feed="$TMP_DIR/distfeeds.conf"
    original="$TMP_DIR/original"
    printf "%s\n" \
        "src/gz base https://downloads.immortalwrt.org/releases/test" \
        "src/gz extra https://mirrors.vsean.net/openwrt/snapshots/test" >"$feed"
    cp "$feed" "$original"
    # Invoked indirectly by enable_temporary_nju_mirror.
    # shellcheck disable=SC2329
    set_feed_file() {
        # shellcheck disable=SC2034
        FEED_FILE=$feed
    }
    enable_temporary_nju_mirror &&
        grep -q "https://mirror.nju.edu.cn/immortalwrt" "$feed" &&
        restore_feed &&
        cmp -s "$feed" "$original"
)

test_unsupported_mirror_feed() (
    TMP_DIR="$TEST_TMP/no-mirror"
    mkdir -p "$TMP_DIR"
    feed="$TMP_DIR/distfeeds.conf"
    printf "%s\n" "src/gz custom https://example.invalid/releases" >"$feed"
    # Invoked indirectly by enable_temporary_nju_mirror.
    # shellcheck disable=SC2329
    set_feed_file() {
        # shellcheck disable=SC2034
        FEED_FILE=$feed
    }
    ! enable_temporary_nju_mirror &&
        grep -q "https://example.invalid/releases" "$feed"
)

assert_true "temporary NJU mirror is restored exactly" \
    test_temporary_mirror_roundtrip
assert_true "temporary mirror rejects unsupported feed without changes" \
    test_unsupported_mirror_feed

printf 'hello\n' >"$TEST_TMP/blob"
assert_true "verify Git blob SHA" \
    verify_git_blob "$TEST_TMP/blob" "ce013625030ba8dba906f756967f9e9ca394464a"
assert_false "reject wrong Git blob SHA" \
    verify_git_blob "$TEST_TMP/blob" "0000000000000000000000000000000000000000"

CPU_ARCH_OVERRIDE=x86_64
CPU_FLAGS_OVERRIDE="cx16 lahf_lm popcnt pni sse4_1"
export CPU_ARCH_OVERRIDE CPU_FLAGS_OVERRIDE
assert_eq "linux-amd64-v1" "$(detect_core_arch)" "select amd64 v1"

CPU_FLAGS_OVERRIDE="cx16 lahf_lm popcnt pni sse4_1 sse4_2 ssse3"
export CPU_FLAGS_OVERRIDE
assert_eq "linux-amd64-v2" "$(detect_core_arch)" "select amd64 v2"

CPU_FLAGS_OVERRIDE="cx16 lahf_lm popcnt pni sse4_1 sse4_2 ssse3 avx avx2 bmi1 bmi2 f16c fma movbe lzcnt"
export CPU_FLAGS_OVERRIDE
assert_eq "linux-amd64-v3" "$(detect_core_arch)" "select amd64 v3 with lzcnt"

CPU_FLAGS_OVERRIDE="cx16 lahf_lm popcnt pni sse4_1 sse4_2 ssse3 avx avx2 bmi1 bmi2 f16c fma movbe abm avx512f"
export CPU_FLAGS_OVERRIDE
assert_eq "linux-amd64-v3" "$(detect_core_arch)" "cap AVX-512 systems at available v3"

CPU_FLAGS_OVERRIDE="cx16 lahf_lm popcnt pni sse4_1 sse4_2 ssse3 avx avx2 bmi1 bmi2 f16c movbe lzcnt"
export CPU_FLAGS_OVERRIDE
assert_eq "linux-amd64-v2" "$(detect_core_arch)" "downgrade v3 when FMA is missing"

CPU_ARCH_OVERRIDE=aarch64
CPU_FLAGS_OVERRIDE=""
export CPU_ARCH_OVERRIDE CPU_FLAGS_OVERRIDE
assert_eq "linux-arm64" "$(detect_core_arch)" "map aarch64"
unset CPU_ARCH_OVERRIDE CPU_FLAGS_OVERRIDE

DOWNLOAD_CALLS="$TEST_TMP/download-calls"
MOCK_SUCCESS_STAGES=""
MOCK_VALID_STAGE=""

curl_download() {
    output=$1
    url=$2
    printf '%s\n' "$url" >>"$DOWNLOAD_CALLS"
    rm -f "$output"

    case "$url" in
        https://cdn.jsdelivr.net/*) stage="jsdelivr" ;;
        https://v6.gh-proxy.org/*) stage="proxy" ;;
        https://raw.githubusercontent.com/*) stage="raw" ;;
        *) stage="unknown" ;;
    esac

    case " $MOCK_SUCCESS_STAGES " in
        *" $stage "*)
            if [ "$stage" = "$MOCK_VALID_STAGE" ]; then
                printf 'valid' >"$output"
            else
                printf 'corrupt' >"$output"
            fi
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

verify_package_file() {
    [ "$(cat "$1" 2>/dev/null)" = "valid" ]
}

run_download_case() {
    expected_calls=$1
    success_stages=$2
    valid_stage=$3
    expected_status=$4
    name=$5
    : >"$DOWNLOAD_CALLS"
    MOCK_SUCCESS_STAGES=$success_stages
    MOCK_VALID_STAGE=$valid_stage
    output="$TEST_TMP/mock.apk"

    if download_openclash_package "pkg.apk" 5 deadbeef "$output" >/dev/null 2>&1; then
        status=0
    else
        status=1
    fi
    calls=$(wc -l <"$DOWNLOAD_CALLS" | tr -d ' ')

    assert_eq "$expected_status" "$status" "$name status"
    assert_eq "$expected_calls" "$calls" "$name source count"
}

run_download_case 1 "jsdelivr" "jsdelivr" 0 \
    "jsDelivr succeeds without fallback"
run_download_case 2 "proxy" "proxy" 0 \
    "proxy succeeds after jsDelivr"
run_download_case 3 "raw" "raw" 0 \
    "Raw succeeds after proxy"
run_download_case 3 "jsdelivr proxy raw" "raw" 0 \
    "corrupt earlier sources fall through to valid Raw"
run_download_case 3 "" "" 1 \
    "all download sources fail"

mapfile="$TEST_TMP/order"
: >"$DOWNLOAD_CALLS"
MOCK_SUCCESS_STAGES="raw"
MOCK_VALID_STAGE="raw"
download_openclash_package "pkg.apk" 5 deadbeef "$TEST_TMP/order.apk" >/dev/null 2>&1
sed -n '1p' "$DOWNLOAD_CALLS" >"$mapfile"
sed -n '2p' "$DOWNLOAD_CALLS" >>"$mapfile"
sed -n '3p' "$DOWNLOAD_CALLS" >>"$mapfile"
expected_order=$(cat <<'EOF'
https://cdn.jsdelivr.net/gh/vernesong/OpenClash@refs/heads/package/dev/pkg.apk
https://v6.gh-proxy.org/https://raw.githubusercontent.com/vernesong/OpenClash/package/dev/pkg.apk
https://raw.githubusercontent.com/vernesong/OpenClash/package/dev/pkg.apk
EOF
)
assert_eq "$expected_order" "$(cat "$mapfile")" "enforce jsDelivr proxy Raw order"

OPENCLASH_LOG="$TEST_TMP/openclash.log"
printf 'old\n' >"$OPENCLASH_LOG"
start_line=$(log_line_count)
printf '%s\n' \
    'Config File Format Validation Failed, Trying To Download Without Agent...' \
    'Config File【test】Update Successful!' >>"$OPENCLASH_LOG"
assert_false "ignore recoverable subscription fallback log" \
    new_log_has_subscription_error "$start_line"

start_line=$(log_line_count)
printf '%s\n' '【test】Update Error, Please Try Again Later...' >>"$OPENCLASH_LOG"
assert_true "detect final subscription failure" \
    new_log_has_subscription_error "$start_line"

start_line=$(log_line_count)
printf '%s\n' 'Chnroute Cidr List Update Error, Please Try Again Later...' >>"$OPENCLASH_LOG"
assert_true "detect resource updater failure hidden behind exit zero" \
    new_log_has_error "$start_line"

available_kb() {
    printf '%s\n' "$MOCK_AVAILABLE_KB"
}

MOCK_AVAILABLE_KB=40000
assert_true "model fits with safety reserve" model_fits 31687468
MOCK_AVAILABLE_KB=31000
assert_false "model rejected without safety reserve" model_fits 31687468

mkdir -p "$TEST_TMP/etc"
dd if=/dev/zero of="$TEST_TMP/etc/Country.mmdb" bs=1024 count=11 2>/dev/null
printf '\253\315\357MaxMind.com' >>"$TEST_TMP/etc/Country.mmdb"
assert_true "validate MMDB marker and minimum size" \
    valid_mmdb_file "$TEST_TMP/etc/Country.mmdb"

printf '<html>' >"$TEST_TMP/etc/GeoIP.dat"
dd if=/dev/zero bs=1024 count=11 2>/dev/null >>"$TEST_TMP/etc/GeoIP.dat"
assert_false "reject HTML database response" \
    valid_data_file "$TEST_TMP/etc/GeoIP.dat"

fake_init="$TEST_TMP/openclash-init"
cat >"$fake_init" <<'EOF'
#!/bin/sh
case "$1" in
    enable | restart) exit 0 ;;
    status) echo failed; exit 0 ;;
esac
EOF
chmod +x "$fake_init"

if (
    # shellcheck disable=SC2030
    OPENCLASH_INIT="$fake_init"
    export OPENCLASH_INIT
    # shellcheck disable=SC2329
    uci() { return 0; }
    # shellcheck disable=SC2329
    pidof() { return 1; }
    # shellcheck disable=SC2329
    sleep() { :; }
    start_openclash
) >/dev/null 2>&1; then
    fail "service failure must return nonzero"
else
    pass "service failure must return nonzero"
fi

subscription_line=$(grep -n 'update_subscriptions$' "$INSTALLER" | tail -n 1 | cut -d: -f1)
preset_line=$(grep -n 'apply_user_preset$' "$INSTALLER" | tail -n 1 | cut -d: -f1)
if [ "$preset_line" -gt "$subscription_line" ]; then
    pass "user preset remains final configuration override"
else
    fail "user preset remains final configuration override"
fi

run_main_integration() (
    manager=$1
    root="$TEST_TMP/integration-$manager"
    mock_bin="$root/bin"
    state="$root/state"
    share="$root/share"
    etc_dir="$root/etc-openclash"
    mkdir -p "$mock_bin" "$state" "$share" "$etc_dir/core" "$etc_dir/config"

    if [ "$manager" = "opkg" ]; then
        package_name="luci-app-openclash_0.47.099_all.ipk"
        package_file="$root/package.ipk"
    else
        package_name="luci-app-openclash-0.47.099.apk"
        package_file="$root/package.apk"
    fi

    printf 'fake package payload\n' >"$package_file"
    package_size=$(wc -c <"$package_file" | tr -d ' ')
    package_sha=$(
        {
            printf 'blob %s\0' "$package_size"
            cat "$package_file"
        } | sha1sum | awk '{print $1}'
    )

    cat >"$root/package.json" <<EOF
[
  {
    "name": "$package_name",
    "sha": "$package_sha",
    "size": $package_size,
    "download_url": "https://example.invalid/openclash.ipk"
  }
]
EOF

    cat >"$root/hosts" <<'EOF'
20.205.243.168 api.github.com
185.199.111.133 raw.githubusercontent.com
20.205.243.166 github.com
EOF

    printf '%s\n' "0.47.098" >"$state/version"
    printf '%s\n' "Meta" >"$state/core_type"
    printf '%s\n' "$etc_dir/config/Clash.yaml" >"$state/config_path"
    printf '%s\n' "0" >"$state/smart_enable"
    printf '%s\n' "0" >"$state/smart_enable_lgbm"
    printf '%s\n' "0" >"$state/small_flash_memory"
    printf 'proxies: []\nproxy-groups: []\nrules: []\n' >"$etc_dir/config/Clash.yaml"

    cat >"$mock_bin/id" <<'EOF'
#!/bin/sh
[ "$1" = "-u" ] && echo 0
EOF

    cat >"$mock_bin/fw4" <<'EOF'
#!/bin/sh
exit 0
EOF

    if [ "$manager" = "opkg" ]; then
        cat >"$mock_bin/opkg" <<'EOF'
#!/bin/sh
dry_run=0
if [ "$1" = "--noaction" ]; then
    dry_run=1
    shift
fi
case "$1" in
    update)
        exit 0
        ;;
    status)
        printf 'Package: luci-app-openclash\nVersion: %s\n' "$(cat "$MOCK_STATE/version")"
        ;;
    install)
        for arg in "$@"; do
            case "$arg" in
                *.ipk)
                    [ "$dry_run" -eq 1 ] && exit 0
                    printf '%s\n' "0.47.099" >"$MOCK_STATE/version"
                    exit 0
                    ;;
            esac
        done
        exit 0
        ;;
esac
exit 0
EOF
    else
        cat >"$mock_bin/apk" <<'EOF'
#!/bin/sh
case "$1" in
    update)
        exit 0
        ;;
    list)
        printf 'luci-app-openclash-%s noarch {mock} [installed]\n' "$(cat "$MOCK_STATE/version")"
        ;;
    add)
        for arg in "$@"; do
            case "$arg" in
                *.apk)
                    case " $* " in
                        *" -s "*) exit 0 ;;
                    esac
                    printf '%s\n' "0.47.099" >"$MOCK_STATE/version"
                    exit 0
                    ;;
            esac
        done
        exit 0
        ;;
esac
exit 0
EOF
    fi

    cat >"$mock_bin/uci" <<'EOF'
#!/bin/sh
[ "$1" = "-q" ] && shift
cmd=$1
shift
case "$cmd" in
    get)
        key=${1##*.}
        [ -f "$MOCK_STATE/$key" ] || exit 1
        cat "$MOCK_STATE/$key"
        ;;
    set)
        assignment=$1
        key=${assignment%%=*}
        key=${key##*.}
        value=${assignment#*=}
        printf '%s\n' "$value" >"$MOCK_STATE/$key"
        ;;
    commit)
        exit 0
        ;;
    show)
        exit 0
        ;;
esac
EOF

    cat >"$mock_bin/curl" <<'EOF'
#!/bin/sh
output=""
url=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        -o)
            output=$2
            shift 2
            ;;
        http://* | https://*)
            url=$1
            shift
            ;;
        *)
            shift
            ;;
    esac
done

case "$url" in
    *raw.hellogithub.com/hosts)
        cp "$MOCK_ROOT/hosts" "$output"
        ;;
    *api.github.com/repos/vernesong/OpenClash/contents/dev*)
        cp "$MOCK_ROOT/package.json" "$output"
        ;;
    *luci-app-openclash_0.47.099_all.ipk)
        cp "$MOCK_ROOT/package.ipk" "$output"
        ;;
    *luci-app-openclash-0.47.099.apk)
        cp "$MOCK_ROOT/package.apk" "$output"
        ;;
    *OpenClash@core/* | *raw.githubusercontent.com/vernesong/OpenClash/core/*)
        exit 0
        ;;
    *)
        exit 1
        ;;
esac
EOF

    cat >"$mock_bin/ruby" <<'EOF'
#!/bin/sh
exit 0
EOF

    cat >"$mock_bin/pidof" <<'EOF'
#!/bin/sh
[ "$1" = "clash" ]
EOF

    cat >"$mock_bin/sleep" <<'EOF'
#!/bin/sh
exit 0
EOF

    cat >"$share/openclash_core.sh" <<EOF
#!/bin/sh
printf '%s\n%s\n' 'alpha-test' 'alpha-smart-test' >/tmp/clash_last_version
cat >"$etc_dir/core/clash_meta" <<'CORE'
#!/bin/sh
case "\$1" in
    -v) echo 'Mihomo Meta alpha-test linux test' ;;
    -t) exit 0 ;;
esac
CORE
chmod +x "$etc_dir/core/clash_meta"
EOF

    cat >"$share/openclash_geo.sh" <<EOF
#!/bin/sh
dd if=/dev/zero of="$etc_dir/GeoIP.dat" bs=1024 count=11 2>/dev/null
dd if=/dev/zero of="$etc_dir/GeoSite.dat" bs=1024 count=11 2>/dev/null
dd if=/dev/zero of="$etc_dir/ASN.mmdb" bs=1024 count=11 2>/dev/null
printf '\\253\\315\\357MaxMind.com' >>"$etc_dir/ASN.mmdb"
dd if=/dev/zero of="$etc_dir/Country.mmdb" bs=1024 count=11 2>/dev/null
printf '\\253\\315\\357MaxMind.com' >>"$etc_dir/Country.mmdb"
EOF

    cat >"$share/openclash_chnroute.sh" <<EOF
#!/bin/sh
dd if=/dev/zero of="$etc_dir/china_ip_route.ipset" bs=1024 count=2 2>/dev/null
dd if=/dev/zero of="$etc_dir/china_ip6_route.ipset" bs=1024 count=1 2>/dev/null
EOF

    cat >"$share/openclash.sh" <<'EOF'
#!/bin/sh
exit 0
EOF

    cat >"$root/openclash-init" <<'EOF'
#!/bin/sh
case "$1" in
    enable | restart) exit 0 ;;
    status) echo running; exit 0 ;;
esac
EOF

    chmod +x "$mock_bin"/* "$share"/* "$root/openclash-init"

    export MOCK_ROOT="$root"
    export MOCK_STATE="$state"
    export PATH="$mock_bin:$PATH"
    export OPENCLASH_SHARE_DIR="$share"
    export OPENCLASH_ETC_DIR="$etc_dir"
    # shellcheck disable=SC2031
    export OPENCLASH_INIT="$root/openclash-init"
    export OPENCLASH_LOG="$root/openclash.log"
    export OPENCLASH_PRESET="$root/no-preset"
    export LOCK_DIR="$root/lock"
    export OPENCLASH_INSTALLER_LIB_ONLY=0

    sh "$INSTALLER" >"$root/output.log" 2>&1
    grep -q '安装、更新和验证全部完成' "$root/output.log"
)

for manager in opkg apk; do
    if run_main_integration "$manager"; then
        pass "complete mocked $manager main workflow"
    else
        fail "complete mocked $manager main workflow"
        cat "$TEST_TMP/integration-$manager/output.log" >&2
    fi
done

printf '# tests: %d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
