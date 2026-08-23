#!/bin/sh
set -eu

PROJECT_ROOT="$(CDPATH='' cd -- "$(dirname "$0")/../.." && pwd)"
INVALID_FILE_MODES="$(mktemp)"
trap 'rm -f "$INVALID_FILE_MODES"' EXIT HUP INT TERM

printf 'Validating executable bits in Git...\n'
git -C "$PROJECT_ROOT" ls-files --stage |
    while read -r file_mode _object_id _stage file_path; do
        case "$file_path" in
            *.sh)
                if [ "$file_mode" != '100755' ]; then
                    printf '%s: expected 100755, got %s\n' "$file_path" "$file_mode"
                fi
                ;;
            *)
                if [ "$file_mode" = '100755' ]; then
                    printf '%s: expected a non-executable mode, got %s\n' "$file_path" "$file_mode"
                fi
                ;;
        esac
    done >"$INVALID_FILE_MODES"

if [ -s "$INVALID_FILE_MODES" ]; then
    printf 'Repository checks: invalid executable bits in Git:\n' >&2
    cat "$INVALID_FILE_MODES" >&2
    exit 1
fi
