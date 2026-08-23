#!/bin/sh
set -eu

PROJECT_ROOT="$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)"

fail() {
    printf 'Development setup: %s\n' "$1" >&2
    exit 1
}

run_as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        fail "root access is required to install operating-system packages."
    fi
}

append_package() {
    package_name="$1"
    if [ -z "$MISSING_PACKAGES" ]; then
        MISSING_PACKAGES="$package_name"
    else
        MISSING_PACKAGES="${MISSING_PACKAGES} ${package_name}"
    fi
}

install_system_packages() {
    [ -n "$MISSING_PACKAGES" ] || return 0

    printf 'Installing development packages: %s\n' "$MISSING_PACKAGES"
    # Word splitting is intentional: this list contains package names only.
    # shellcheck disable=SC2086
    if command -v apt-get >/dev/null 2>&1; then
        run_as_root apt-get update
        # shellcheck disable=SC2086
        run_as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $MISSING_PACKAGES
    elif command -v apk >/dev/null 2>&1; then
        # shellcheck disable=SC2086
        run_as_root apk add --no-cache $MISSING_PACKAGES
    elif command -v dnf >/dev/null 2>&1; then
        # shellcheck disable=SC2086
        run_as_root dnf install -y $MISSING_PACKAGES
    elif command -v microdnf >/dev/null 2>&1; then
        # shellcheck disable=SC2086
        run_as_root microdnf install -y $MISSING_PACKAGES
    elif command -v yum >/dev/null 2>&1; then
        # shellcheck disable=SC2086
        run_as_root yum install -y $MISSING_PACKAGES
    else
        fail "no supported package manager was found (apt, apk, dnf, microdnf, or yum)."
    fi
}

MISSING_PACKAGES=""
command -v curl >/dev/null 2>&1 || append_package curl
command -v shellcheck >/dev/null 2>&1 || append_package shellcheck
command -v shfmt >/dev/null 2>&1 || append_package shfmt
install_system_packages

if ! command -v npm >/dev/null 2>&1; then
    fail "npm is required; use the repository dev container or install a current Node.js release."
fi

printf 'Installing project development dependencies...\n'
npm ci --ignore-scripts --prefix "$PROJECT_ROOT"

printf 'Development dependencies are available.\n'
