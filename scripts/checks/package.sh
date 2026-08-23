#!/bin/sh
set -eu

PROJECT_ROOT="$(CDPATH='' cd -- "$(dirname "$0")/../.." && pwd)"
PACKAGE_OUTPUT="$(mktemp -d)"
trap 'rm -rf "$PACKAGE_OUTPUT"' EXIT HUP INT TERM

printf 'Packaging Features...\n'
"$PROJECT_ROOT/node_modules/.bin/devcontainer" \
    features package \
    --force-clean-output-folder \
    --output-folder "$PACKAGE_OUTPUT" \
    "$PROJECT_ROOT/src"
