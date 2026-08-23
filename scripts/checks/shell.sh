#!/bin/sh
set -eu

PROJECT_ROOT="$(CDPATH='' cd -- "$(dirname "$0")/../.." && pwd)"

printf 'Linting shell scripts...\n'
cd "$PROJECT_ROOT"
find .devcontainer scripts src test -type f -name '*.sh' -exec shellcheck {} +
