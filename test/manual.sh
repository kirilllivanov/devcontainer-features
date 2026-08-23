#!/bin/sh
set -eu

PROJECT_ROOT="$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)"
: "${SELECTED_IMAGE:?SELECTED_IMAGE is required}"
SELECTED_LOG_LEVEL="${SELECTED_LOG_LEVEL:-info}"

run_tests() {
    set -- \
        --image "$SELECTED_IMAGE" \
        --log-level "$SELECTED_LOG_LEVEL" \
        "$@"
    if [ -n "${SELECTED_FEATURE:-}" ]; then
        set -- "$@" --feature "$SELECTED_FEATURE"
    fi

    exec sh "$PROJECT_ROOT/test/features/run.sh" "$@"
}

run_tests "$@"
