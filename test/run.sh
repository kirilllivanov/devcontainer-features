#!/bin/sh
set -eu

PROJECT_ROOT="$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)"

printf 'Running unit tests...\n'
sh "$PROJECT_ROOT/test/unit/run.sh"

printf '\nRunning Feature tests...\n'
sh "$PROJECT_ROOT/test/features/run.sh" "$@"

printf '\nAll tests passed.\n'
