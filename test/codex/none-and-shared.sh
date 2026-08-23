#!/bin/sh
set -eu

TEST_DIR="$(CDPATH='' cd -- "$(dirname "$0")" && pwd)"
# shellcheck source=test/codex/test-lib.sh
. "$TEST_DIR/test-lib.sh"

check "Codex CLI installation is disabled" sh -c '! command -v codex'
check "shared storage is selected" test "$(readlink /run/codex/active)" = "/run/codex/shared"
check "shared storage is accessible to all users" test "$(stat -c '%a' /run/codex/shared)" = "777"
check "automatic Codex home exists" test "$(readlink "${HOME}/.codex")" = "/run/codex/active"

reportResults
