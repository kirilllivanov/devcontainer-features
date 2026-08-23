#!/bin/sh
set -eu

: "${CODEX_INSTALL_DIR:?CODEX_INSTALL_DIR is required}"
: "${MOCK_INSTALLER_LOG:?MOCK_INSTALLER_LOG is required}"

release="latest"
while [ "$#" -gt 0 ]; do
    case "$1" in
        --release)
            release="$2"
            shift
            ;;
    esac
    shift
done

mkdir -p "$CODEX_INSTALL_DIR"
printf '%s' "$release" >"$MOCK_INSTALLER_LOG"
# The generated mock intentionally evaluates this expression when it runs.
# shellcheck disable=SC2016
printf '%s\n' '#!/bin/sh' 'printf "mock codex %s\n" "${MOCK_CODEX_VERSION:-unknown}"' >"${CODEX_INSTALL_DIR}/codex"
chmod +x "${CODEX_INSTALL_DIR}/codex"
