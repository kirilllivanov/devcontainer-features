#!/bin/sh
set -eu

PROJECT_ROOT="$(CDPATH='' cd -- "$(dirname "$0")/../.." && pwd)"

printf 'Checking shell script formatting...\n'
cd "$PROJECT_ROOT"
shfmt -d -i 4 -ci .devcontainer scripts src test
