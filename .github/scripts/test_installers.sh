#!/bin/sh
# Test doubles and variables below are consumed indirectly by sourced helpers.
# shellcheck disable=SC2034,SC2329
set -eu

fail() {
    printf 'installer contract test failed: %s\n' "$1" >&2
    exit 1
}

run_suite() (
    installer=$1
    OPENCLASH_INSTALLER_LIB_ONLY=1
    export OPENCLASH_INSTALLER_LIB_ONLY
    # shellcheck disable=SC1090
    . "$installer"

    temporary=$(mktemp -d)
    trap 'rm -rf "$temporary"' EXIT HUP INT TERM

    version_file="$temporary/version"
    printf '%s\n' 'v0.47.999' >"$version_file"
    [ "$(parse_package_version "$version_file")" = '0.47.999' ] ||
        fail "$installer version parsing"

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
    [ "$(printf '%b' "$attempts")" = "$expected_attempts" ] ||
        fail "$installer download order"
)

run_suite shell/install_openclash_dev.sh
run_suite shell/install_openclash_dev_update.sh
printf '%s\n' 'Installer behavior contract tests passed.'
