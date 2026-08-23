#!/bin/sh
set -eu

: "${MOCK_CODE_LOG:?MOCK_CODE_LOG is required}"

if [ "${1:-}" = "--version" ]; then
    exit "${MOCK_CODE_VERSION_STATUS:-0}"
fi

printf '%s\n' "$@" >"$MOCK_CODE_LOG"
