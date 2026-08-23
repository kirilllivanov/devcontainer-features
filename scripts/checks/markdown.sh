#!/bin/sh
set -eu

PROJECT_ROOT="$(CDPATH='' cd -- "$(dirname "$0")/../.." && pwd)"

printf 'Linting Markdown files...\n'
cd "$PROJECT_ROOT"
"$PROJECT_ROOT/node_modules/.bin/markdownlint-cli2"
