#!/bin/sh
set -eu

FEATURE_DIR="${CODEX_FEATURE_DIR:-/usr/local/share/codex-feature}"
EXTENSION_ID="openai.chatgpt"

find_vscode_cli() {
    if command -v code >/dev/null 2>&1; then
        candidate="$(command -v code)"
        if "$candidate" --version >/dev/null 2>&1; then
            printf '%s\n' "$candidate"
            return 0
        fi
    fi

    if [ -n "${VSCODE_CWD:-}" ]; then
        candidate="${VSCODE_CWD}/bin/code-server"
        if [ -x "$candidate" ] && "$candidate" --version >/dev/null 2>&1; then
            printf '%s\n' "$candidate"
            return 0
        fi
    fi

    if [ "${CODEX_FEATURE_VSCODE_ROOTS+x}" = "x" ]; then
        vscode_roots="$CODEX_FEATURE_VSCODE_ROOTS"
    else
        vscode_home="${HOME:-/root}"
        vscode_roots="/vscode/vscode-server:/vscode/vscode-server-insiders:${vscode_home}/.vscode-server:${vscode_home}/.vscode-server-insiders:${vscode_home}/.vscode-remote"
    fi

    original_ifs="$IFS"
    IFS=':'
    for vscode_root in $vscode_roots; do
        [ -d "$vscode_root" ] || continue
        candidate="$(find "$vscode_root" -path '*/bin/code-server' -type f -print -quit 2>/dev/null)"
        if [ -n "$candidate" ] && [ -x "$candidate" ] &&
            "$candidate" --version >/dev/null 2>&1; then
            IFS="$original_ifs"
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    IFS="$original_ifs"

    return 1
}

if [ -f "${FEATURE_DIR}/extension-version" ]; then
    EXTENSION_VERSION="$(sed -n '1p' "${FEATURE_DIR}/extension-version")"
else
    EXTENSION_VERSION="latest"
fi

[ "$EXTENSION_VERSION" != "none" ] || exit 0

if ! VSCODE_CLI="$(find_vscode_cli)"; then
    printf 'Codex feature: VS Code CLI is unavailable; skipping extension installation.\n' >&2
    exit 0
fi

if [ "$EXTENSION_VERSION" = "latest" ]; then
    extension_reference="$EXTENSION_ID"
else
    extension_reference="${EXTENSION_ID}@${EXTENSION_VERSION}"
fi

printf 'Codex feature: installing VS Code extension %s\n' "$extension_reference"
"$VSCODE_CLI" --install-extension "$extension_reference" --force
