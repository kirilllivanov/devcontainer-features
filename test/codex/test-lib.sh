#!/bin/sh

FAILED_CHECKS=0

check() {
    label="$1"
    shift

    printf '\nTesting %s...\n' "$label"
    if "$@"; then
        printf 'Passed: %s\n' "$label"
    else
        printf 'Failed: %s\n' "$label" >&2
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

reportResults() {
    if [ "$FAILED_CHECKS" -ne 0 ]; then
        printf '\n%d test check(s) failed.\n' "$FAILED_CHECKS" >&2
        exit 1
    fi

    printf '\nTests passed.\n'
}
