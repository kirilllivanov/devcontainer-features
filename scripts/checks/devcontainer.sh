#!/bin/sh
set -eu

PROJECT_ROOT="$(CDPATH='' cd -- "$(dirname "$0")/../.." && pwd)"

printf 'Validating devcontainer.json...\n'
"$PROJECT_ROOT/node_modules/.bin/devcontainer" \
    read-configuration --workspace-folder "$PROJECT_ROOT" >/dev/null
