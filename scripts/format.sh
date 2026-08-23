#!/bin/sh
set -eu

PROJECT_ROOT="$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)"

cd "$PROJECT_ROOT"
"$PROJECT_ROOT/node_modules/.bin/eslint" "**/*.mjs" "**/*.json" "**/*.jsonc" --fix
shfmt -w -i 4 -ci .devcontainer scripts src test

printf 'Formatting complete.\n'
