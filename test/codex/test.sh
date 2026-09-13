#!/bin/sh
set -eu

TEST_DIR="$(CDPATH='' cd -- "$(dirname "$0")" && pwd)"
# shellcheck source=test/codex/test-lib.sh
. "$TEST_DIR/test-lib.sh"

check "Codex executable is installed" command -v codex
check "Codex reports its version" codex --version
check "Git is installed" command -v git
check "curl is installed" command -v curl
check "ripgrep is installed" command -v rg
check "fd is installed" command -v fd
check "jq is installed" command -v jq
check "file is installed" command -v file
check "less is installed" command -v less
check "patch is installed" command -v patch
check "unzip is installed" command -v unzip
check "zip is installed" command -v zip
check "tree is installed" command -v tree
check "rsync is installed" command -v rsync
check "SSH client is installed" command -v ssh
check "Bash is installed" command -v bash
check "diff is installed" command -v diff
check "find is installed" command -v find
check "xargs is installed" command -v xargs
check "tar is installed" command -v tar
check "gzip is installed" command -v gzip
check "xz is installed" command -v xz
check "ps is installed" command -v ps
check "CODEX_HOME is exported" test "$CODEX_HOME" = "/run/codex/active"
check "per-container storage is selected" test "$(readlink /run/codex/active)" = "/run/codex/per-container"
check "default user-facing Codex home exists" test -L "${HOME}/.codex"

reportResults
