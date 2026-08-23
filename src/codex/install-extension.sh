#!/bin/sh
set -eu

FEATURE_DIR="${CODEX_FEATURE_DIR:-/usr/local/share/codex-feature}"
EXTENSION_ID="openai.chatgpt"

if [ -f "${FEATURE_DIR}/extension-version" ]; then
    EXTENSION_VERSION="$(sed -n '1p' "${FEATURE_DIR}/extension-version")"
else
    EXTENSION_VERSION="latest"
fi

[ "$EXTENSION_VERSION" != "none" ] || exit 0

if ! command -v code >/dev/null 2>&1 || ! code --version >/dev/null 2>&1; then
    printf 'Codex feature: VS Code remote CLI is unavailable; skipping extension installation.\n' >&2
    exit 0
fi

if [ "$EXTENSION_VERSION" = "latest" ]; then
    extension_reference="$EXTENSION_ID"
else
    extension_reference="${EXTENSION_ID}@${EXTENSION_VERSION}"
fi

printf 'Codex feature: installing VS Code extension %s\n' "$extension_reference"
code --install-extension "$extension_reference" --force
