#!/bin/sh
set -eu

: "${MOCK_CODE_LOG:?MOCK_CODE_LOG is required}"

if [ "${1:-}" = "--version" ]; then
    case "${0##*/}" in
        code-server) exit "${MOCK_CODE_SERVER_VERSION_STATUS:-${MOCK_CODE_VERSION_STATUS:-0}}" ;;
        *) exit "${MOCK_CODE_VERSION_STATUS:-0}" ;;
    esac
fi

printf '%s\n' "$@" >"$MOCK_CODE_LOG"
