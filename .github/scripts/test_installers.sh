#!/bin/sh
# Test doubles and variables below are consumed indirectly by sourced helpers.
# shellcheck disable=SC2034,SC2329
set -eu

fail() {
    printf 'installer contract test failed: %s\n' "$1" >&2
    exit 1
}

assert_equal() {
    expected=$1
    actual=$2
    label=$3
    [ "$actual" = "$expected" ] ||
        fail "$label (expected '$expected', got '$actual')"
}

run_package_suite() (
    installer=$1
    OPENCLASH_INSTALLER_LIB_ONLY=1
    export OPENCLASH_INSTALLER_LIB_ONLY
    # shellcheck disable=SC1090
    . "$installer"

    temporary=$(mktemp -d)
    trap 'rm -rf "$temporary"' EXIT HUP INT TERM
    TMP_DIR=$temporary

    version_file="$temporary/version"
    printf '%s\n' 'v0.47.999' >"$version_file"
    assert_equal '0.47.999' "$(parse_package_version "$version_file")" \
        "$installer version parsing"

    metadata_file="$temporary/package-metadata.json"
    printf '%s\n' \
        '{"files":[{"name":"/dev/package.apk","hash":"fWQiBKwyZ7JPctfpC1M0WecbeJLl9PIEfSigmUz9D9U=","size":9251834}]}' \
        >"$metadata_file"
    parsed=$(parse_jsdelivr_package_metadata "$metadata_file" package.apk)
    assert_equal \
        'fWQiBKwyZ7JPctfpC1M0WecbeJLl9PIEfSigmUz9D9U= 9251834' \
        "$parsed" "$installer jsDelivr metadata parsing"
    if command -v base64 >/dev/null 2>&1 && command -v od >/dev/null 2>&1; then
        assert_equal \
            '7d642204ac3267b24f72d7e90b533459e71b7892e5f4f2047d28a0994cfd0fd5' \
            "$(base64_sha256_to_hex 'fWQiBKwyZ7JPctfpC1M0WecbeJLl9PIEfSigmUz9D9U=')" \
            "$installer jsDelivr Base64 SHA-256 decoding"
    fi

    package_file="$temporary/package.bin"
    printf 'test' >"$package_file"
    PACKAGE_MIN_BYTES=1
    PKG_MGR=opkg
    opkg() {
        return 0
    }
    good_sha256='aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
    bad_sha256='bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
    PACKAGE_EXPECTED_SIZE=4
    PACKAGE_EXPECTED_SHA256=$good_sha256
    file_sha256() {
        printf '%s\n' "$good_sha256"
    }
    verify_package_file "$package_file" ||
        fail "$installer package metadata match"

    PACKAGE_EXPECTED_SIZE=5
    if verify_package_file "$package_file"; then
        fail "$installer package size mismatch rejection"
    fi
    PACKAGE_EXPECTED_SIZE=4
    file_sha256() {
        printf '%s\n' "$bad_sha256"
    }
    if verify_package_file "$package_file"; then
        fail "$installer package hash mismatch rejection"
    fi

    file_sha256() {
        return 1
    }
    verify_package_file "$package_file" ||
        fail "$installer missing SHA-256 tool fallback"
    PACKAGE_EXPECTED_SIZE=''
    PACKAGE_EXPECTED_SHA256=''
    verify_package_file "$package_file" ||
        fail "$installer metadata unavailable fallback"

    curl() {
        return 1
    }
    PACKAGE_EXPECTED_SIZE=999
    PACKAGE_EXPECTED_SHA256=$bad_sha256
    fetch_package_integrity_metadata deadbeef package.apk ||
        fail "$installer metadata fetch must be non-blocking"
    assert_equal '' "$PACKAGE_EXPECTED_SIZE" \
        "$installer unavailable metadata clears expected size"
    assert_equal '' "$PACKAGE_EXPECTED_SHA256" \
        "$installer unavailable metadata clears expected hash"

    fetch_package_integrity_metadata() {
        PACKAGE_EXPECTED_SIZE=''
        PACKAGE_EXPECTED_SHA256=''
        return 0
    }
    attempts=''
    curl_download() {
        attempts="${attempts}${2}\n"
        case "$2" in
            https://raw.example/*) return 0 ;;
            *) return 1 ;;
        esac
    }
    verify_package_file() {
        return 0
    }
    RAW_PACKAGE_PREFIX='https://raw.example/repository'
    JSDELIVR_PACKAGE_PREFIX='https://cdn.example/repository@'
    GH_PROXY_PREFIX='https://proxy.example/'
    download_openclash_package deadbeef package.apk "$temporary/package.apk" ||
        fail "$installer download fallback"
    expected_attempts='https://cdn.example/repository@deadbeef/dev/package.apk
https://proxy.example/https://raw.example/repository/deadbeef/dev/package.apk
https://raw.example/repository/deadbeef/dev/package.apk'
    assert_equal "$expected_attempts" "$(printf '%b' "$attempts")" \
        "$installer download order"

    attempts=''
    verification_count=0
    curl_download() {
        attempts="${attempts}${2}\n"
        return 0
    }
    verify_package_file() {
        verification_count=$((verification_count + 1))
        [ "$verification_count" -eq 3 ]
    }
    download_openclash_package deadbeef package.apk "$temporary/package.apk" ||
        fail "$installer known mismatch mirror fallback"
    assert_equal "$expected_attempts" "$(printf '%b' "$attempts")" \
        "$installer mismatch preserves source order"

    attempts=''
    verify_package_file() {
        return 1
    }
    if download_openclash_package deadbeef package.apk "$temporary/package.apk"; then
        fail "$installer all-mirror mismatch rejection"
    fi
    assert_equal "$expected_attempts" "$(printf '%b' "$attempts")" \
        "$installer all-mirror mismatch attempts"
)

run_feed_suite() (
    installer=$1
    OPENCLASH_INSTALLER_LIB_ONLY=1
    export OPENCLASH_INSTALLER_LIB_ONLY
    # shellcheck disable=SC1090
    . "$installer"

    temporary=$(mktemp -d)
    trap 'rm -rf "$temporary"' EXIT HUP INT TERM
    source_file="$temporary/distfeeds.list"
    target_file="$temporary/distfeeds.mirror"
    DISTRO_ID=immortalwrt
    printf '%s\n' \
        'https://packages.example.invalid/custom/prefix/snapshots/packages/x86_64/base/packages.adb' \
        >"$source_file"
    rewrite_feed_to_mirror "$source_file" "$target_file" ||
        fail "$installer arbitrary ImmortalWrt feed normalization"
    assert_equal \
        'https://mirrors.cernet.edu.cn/immortalwrt/snapshots/packages/x86_64/base/packages.adb' \
        "$(cat "$target_file")" "$installer ImmortalWrt CERNET target"

    printf '%s\n' \
        'src/gz custom_core http://mirror.example/releases/24.10.4/targets/x86/64/packages' \
        'src/gz custom_extra https://another.example/prefix/releases/24.10.4/packages/x86_64/base' \
        >"$source_file"
    DISTRO_ID=openwrt
    rewrite_feed_to_mirror "$source_file" "$target_file" ||
        fail "$installer arbitrary OpenWrt feed normalization"
    expected_openwrt='src/gz custom_core https://cernet.mirrors.ustc.edu.cn/openwrt/releases/24.10.4/targets/x86/64/packages
src/gz custom_extra https://cernet.mirrors.ustc.edu.cn/openwrt/releases/24.10.4/packages/x86_64/base'
    assert_equal "$expected_openwrt" "$(cat "$target_file")" \
        "$installer OpenWrt CERNET targets"

    printf '%s\n' \
        '# preserve comments in the temporary feed' \
        'https://downloads.openwrt.org/snapshots/packages/x86_64/base/packages.adb' \
        'https://packages.example.invalid/vendor/packages.adb' \
        >"$source_file"
    rewrite_feed_to_mirror "$source_file" "$target_file" ||
        fail "$installer OpenWrt snapshot normalization"
    expected_snapshot='# preserve comments in the temporary feed
https://cernet.mirrors.ustc.edu.cn/openwrt/snapshots/packages/x86_64/base/packages.adb'
    assert_equal "$expected_snapshot" "$(cat "$target_file")" \
        "$installer excludes unrelated temporary feeds"

    printf '%s\n' 'https://packages.example.invalid/vendor/packages.adb' \
        >"$source_file"
    if rewrite_feed_to_mirror "$source_file" "$target_file"; then
        fail "$installer feed without a standard distribution path"
    fi

    live_feed="$temporary/live-distfeeds.list"
    original_feed='https://mirror.user.example/prefix/snapshots/packages/x86_64/base/packages.adb
https://packages.user.example/vendor/packages.adb'
    printf '%s\n' "$original_feed" >"$live_feed"
    TMP_DIR="$temporary/runtime"
    mkdir -p "$TMP_DIR"
    FEED_FILE=$live_feed
    FEED_BACKUP=''
    FEED_CHANGED=0
    DISTRO_ID=immortalwrt
    prepare_temporary_feed ||
        fail "$installer temporary CERNET feed preparation"
    expected_live='https://mirrors.cernet.edu.cn/immortalwrt/snapshots/packages/x86_64/base/packages.adb'
    assert_equal "$expected_live" "$(cat "$live_feed")" \
        "$installer temporary feed content"
    restore_feed || fail "$installer original feed restoration"
    assert_equal "$original_feed" "$(cat "$live_feed")" \
        "$installer exact original feed restoration"
)

run_model_suite() (
    installer=shell/install_openclash_dev_update.sh
    OPENCLASH_INSTALLER_LIB_ONLY=1
    export OPENCLASH_INSTALLER_LIB_ONLY
    # shellcheck disable=SC1090
    . "$installer"

    temporary=$(mktemp -d)
    trap 'rm -rf "$temporary"' EXIT HUP INT TERM
    TMP_DIR=$temporary

    model_sha256='eff76711efede06d7eedc86fb55af91b79bc16bc3f6c4c0222c827a8626095db'
    metadata_file="$temporary/model-release.json"
    printf '%s\n' \
        "{\"assets\":[{\"name\":\"Model.bin\",\"size\":7835385,\"digest\":\"sha256:$model_sha256\"}]}" \
        >"$metadata_file"
    parsed=$(parse_model_release_metadata "$metadata_file" Model.bin)
    assert_equal "7835385 $model_sha256" "$parsed" \
        'LightGBM release metadata parsing'

    fetch_model_release_metadata() {
        return 1
    }
    probe_model_size() {
        printf '%s\n' '100'
    }
    model_fits() {
        return 0
    }
    select_smart_model "$temporary" ||
        fail 'LightGBM API unavailable size-probe fallback'
    assert_equal 'Model-large.bin' "$SELECTED_MODEL" \
        'LightGBM fallback candidate'
    assert_equal '100' "$SELECTED_MODEL_SIZE" \
        'LightGBM fallback size'
    assert_equal '' "$SELECTED_MODEL_SHA256" \
        'LightGBM fallback has no digest'

    printf '%s\n' \
        "{\"assets\":[{\"name\":\"Model-large.bin\",\"size\":200,\"digest\":\"sha256:$model_sha256\"}]}" \
        >"$metadata_file"
    fetch_model_release_metadata() {
        MODEL_METADATA_FILE=$metadata_file
        return 0
    }
    select_smart_model "$temporary" ||
        fail 'LightGBM official metadata selection'
    assert_equal '200' "$SELECTED_MODEL_SIZE" \
        'LightGBM official metadata size'
    assert_equal "$model_sha256" "$SELECTED_MODEL_SHA256" \
        'LightGBM official metadata digest'

    model_file="$temporary/model.bin"
    printf 'new!' >"$model_file"
    file_sha256() {
        printf '%s\n' "$model_sha256"
    }
    verify_model_file "$model_file" 4 "$model_sha256" ||
        fail 'LightGBM size and digest match'
    file_sha256() {
        printf '%064d\n' 0
    }
    if verify_model_file "$model_file" 4 "$model_sha256"; then
        fail 'LightGBM digest mismatch rejection'
    fi
    file_sha256() {
        return 1
    }
    verify_model_file "$model_file" 4 "$model_sha256" ||
        fail 'LightGBM missing SHA-256 tool fallback'

    target="$temporary/active/Model.bin"
    mkdir -p "${target%/*}"
    printf 'old!' >"$target"
    get_effective_core_type() {
        printf '%s\n' 'Smart'
    }
    uci() {
        case "$*" in
            '-q get openclash.config.smart_enable_lgbm') printf '%s\n' '1' ;;
        esac
        return 0
    }
    model_target_path() {
        printf '%s\n' "$target"
    }
    select_smart_model() {
        SELECTED_MODEL='Model.bin'
        SELECTED_MODEL_SIZE=4
        SELECTED_MODEL_URL='https://github.example/Model.bin'
        SELECTED_MODEL_SHA256=$model_sha256
        return 0
    }
    curl_download() {
        printf 'new!' >"$1"
        return 0
    }
    curl_model_direct_fallback() {
        return 1
    }
    file_sha256() {
        printf '%s\n' "$model_sha256"
    }
    update_smart_model || fail 'LightGBM digest-match update'
    assert_equal 'new!' "$(cat "$target")" \
        'LightGBM digest-match atomic replacement'

    proxy_failed_direct_attempted=0
    curl_download() {
        return 1
    }
    curl_model_direct_fallback() {
        proxy_failed_direct_attempted=1
        return 1
    }
    if download_selected_model "$temporary/proxy-failed.bin"; then
        fail 'LightGBM failed proxy download must not report success'
    fi
    assert_equal '0' "$proxy_failed_direct_attempted" \
        'LightGBM proxy network failure skips direct GitHub'

    printf 'old!' >"$target"
    direct_attempted=0
    curl_download() {
        printf 'bad!' >"$1"
        return 0
    }
    file_sha256() {
        printf '%064d\n' 0
    }
    curl_model_direct_fallback() {
        direct_attempted=1
        return 1
    }
    update_smart_model || fail 'LightGBM mismatch remains non-blocking'
    assert_equal '1' "$direct_attempted" \
        'LightGBM mismatch attempts official direct URL'
    assert_equal 'old!' "$(cat "$target")" \
        'LightGBM mismatch preserves active model'
)

run_package_suite shell/install_openclash_dev.sh
run_package_suite shell/install_openclash_dev_update.sh
run_feed_suite shell/install_openclash_dev.sh
run_feed_suite shell/install_openclash_dev_update.sh
run_model_suite
printf '%s\n' 'Installer behavior contract tests passed.'
