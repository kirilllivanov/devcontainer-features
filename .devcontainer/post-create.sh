#!/bin/sh
set -eu

PROJECT_ROOT="$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)"
UID_GID="$(id -u):$(id -g)"

fail() {
    printf 'Dev container setup: %s\n' "$1" >&2
    exit 1
}

run_as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        fail "root access is required to configure cache directory ownership."
    fi
}

set -- \
    "$HOME/.cache/typescript" \
    "$HOME/.npm" \
    "$PROJECT_ROOT/node_modules"

run_as_root mkdir -p "$@"

run_as_root chown "$UID_GID" "$@"

sh "$PROJECT_ROOT/scripts/install-dev-dependencies.sh"
