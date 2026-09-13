#!/bin/sh
set -eu

TEST_DIR="$(CDPATH='' cd -- "$(dirname "$0")" && pwd)"
SCENARIO_NAME="${0##*/}"
SCENARIO_NAME="${SCENARIO_NAME%.sh}"
# shellcheck source=test/codex/test-lib.sh
. "$TEST_DIR/test-lib.sh"

check_cli_enabled() {
    command -v codex >/dev/null 2>&1 && codex --version >/dev/null 2>&1
}

check_cli_disabled() {
    ! command -v codex >/dev/null 2>&1
}

check_default_storage() {
    test "$CODEX_HOME" = "/run/codex/active" &&
        test "$(readlink /run/codex/active)" = "/run/codex/per-container" &&
        test -L "${HOME}/.codex"
}

check_shared_storage() {
    test "$(readlink /run/codex/active)" = "/run/codex/shared" &&
        test "$(stat -c '%a' /run/codex/shared)" = "777" &&
        test "$(readlink "${HOME}/.codex")" = "/run/codex/active"
}

check_repository_tools() {
    command -v git >/dev/null 2>&1 &&
        command -v curl >/dev/null 2>&1 &&
        command -v rg >/dev/null 2>&1 &&
        command -v fd >/dev/null 2>&1 &&
        command -v jq >/dev/null 2>&1 &&
        command -v file >/dev/null 2>&1 &&
        command -v less >/dev/null 2>&1 &&
        command -v patch >/dev/null 2>&1 &&
        command -v unzip >/dev/null 2>&1 &&
        command -v zip >/dev/null 2>&1 &&
        command -v tree >/dev/null 2>&1 &&
        command -v rsync >/dev/null 2>&1 &&
        command -v ssh >/dev/null 2>&1 &&
        command -v bash >/dev/null 2>&1 &&
        command -v diff >/dev/null 2>&1 &&
        command -v find >/dev/null 2>&1 &&
        command -v xargs >/dev/null 2>&1 &&
        command -v tar >/dev/null 2>&1 &&
        command -v gzip >/dev/null 2>&1 &&
        command -v xz >/dev/null 2>&1 &&
        command -v ps >/dev/null 2>&1
}

extension_hook_matches() {
    expected_version="$1"
    mock_code_dir="$(mktemp -d)"
    extension_log="${mock_code_dir}/invocation"

    cat >"${mock_code_dir}/code" <<'EOF'
#!/bin/sh
set -eu

case "${1:-}" in
    --version)
        printf '%s\n' '1.0.0'
        ;;
    --install-extension)
        printf '%s\n' "$*" >"$CODE_EXTENSION_LOG"
        ;;
    *)
        exit 2
        ;;
esac
EOF
    chmod +x "${mock_code_dir}/code"

    CODE_EXTENSION_LOG="$extension_log" \
        PATH="${mock_code_dir}:$PATH" \
        /usr/local/share/codex-feature/install-extension.sh || {
        rm -rf "$mock_code_dir"
        return 1
    }

    if [ "$expected_version" = "none" ]; then
        test ! -e "$extension_log"
    else
        test "$(cat "$extension_log")" = \
            "--install-extension openai.chatgpt --force"
    fi
    result="$?"
    rm -rf "$mock_code_dir"
    return "$result"
}

check "repository tools are installed" check_repository_tools

case "$SCENARIO_NAME" in
    none-and-shared-*)
        check "Codex CLI installation is disabled" check_cli_disabled
        check "VS Code extension installation is disabled" \
            extension_hook_matches "none"
        check "shared storage is selected and accessible" check_shared_storage
        ;;
    cli-only-*)
        check "Codex CLI is installed and reports its version" check_cli_enabled
        check "VS Code extension installation is disabled" \
            extension_hook_matches "none"
        check "default per-container storage is selected" check_default_storage
        ;;
    extension-only-*)
        check "Codex CLI installation is disabled" check_cli_disabled
        check "VS Code extension is installed by the lifecycle hook" \
            extension_hook_matches "latest"
        check "default per-container storage is selected" check_default_storage
        ;;
    cli-and-extension-*)
        check "Codex CLI is installed and reports its version" check_cli_enabled
        check "VS Code extension is installed by the lifecycle hook" \
            extension_hook_matches "latest"
        check "default per-container storage is selected" check_default_storage
        ;;
    *)
        printf 'Unknown Codex test scenario: %s\n' "$SCENARIO_NAME" >&2
        exit 2
        ;;
esac

reportResults
