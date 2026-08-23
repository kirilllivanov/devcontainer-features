#!/bin/sh
set -eu

PROJECT_ROOT="$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)"
CHECKS_DIR="$PROJECT_ROOT/scripts/checks"

for check_script in \
    "$CHECKS_DIR/json.sh" \
    "$CHECKS_DIR/markdown.sh" \
    "$CHECKS_DIR/shell.sh" \
    "$CHECKS_DIR/format.sh"; do
    sh "$check_script"
done

printf 'Lint checks passed.\n'
