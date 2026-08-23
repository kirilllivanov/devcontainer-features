#!/bin/sh
set -eu

TEST_DIR="$(CDPATH='' cd -- "$(dirname "$0")" && pwd)"
# shellcheck source=test/codex/test-lib.sh
. "$TEST_DIR/test-lib.sh"

check "Codex executable is installed" command -v codex
check "Codex reports its version" codex --version
check "CODEX_HOME is exported" test "$CODEX_HOME" = "/run/codex/active"
check "per-container storage is selected" test "$(readlink /run/codex/active)" = "/run/codex/per-container"
check "default user-facing Codex home exists" test -L "${HOME}/.codex"

reportResults
