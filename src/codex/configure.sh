#!/bin/sh
set -eu

FEATURE_DIR="${CODEX_FEATURE_DIR:-/usr/local/share/codex-feature}"
STORAGE_ROOT="${CODEX_FEATURE_STORAGE_ROOT:-/run/codex}"
PER_CONTAINER_HOME="${STORAGE_ROOT}/per-container"
SHARED_HOME="${STORAGE_ROOT}/shared"
ACTIVE_HOME="${STORAGE_ROOT}/active"
CODESPACES_HOME="${CODEX_FEATURE_CODESPACES_HOME:-/workspaces/.codex}"

read_option() {
    option_file="$1"
    default_value="$2"
    if [ -f "${FEATURE_DIR}/${option_file}" ]; then
        sed -n '1p' "${FEATURE_DIR}/${option_file}"
    else
        printf '%s\n' "$default_value"
    fi
}

warn() {
    printf 'Codex feature: warning: %s\n' "$1" >&2
}

fail() {
    printf 'Codex feature: %s\n' "$1" >&2
    exit 1
}

run_privileged() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        printf 'Codex feature: %s requires root access and sudo is unavailable.\n' "$1" >&2
        return 1
    fi
}

validate_mode_option() {
    option_name="$1"
    option_value="$2"

    case "$option_value" in
        auto | [0-7][0-7][0-7] | [0-7][0-7][0-7][0-7]) ;;
        *) fail "${option_name} must be auto or a three/four-digit octal mode." ;;
    esac
}

apply_permissions() {
    directory="$1"
    requested_owner="$2"
    requested_directory_mode="$3"
    requested_file_mode="$4"

    if [ "$directory" = "$SHARED_HOME" ]; then
        permission_profile=shared
    else
        permission_profile=private
    fi

    case "$requested_owner" in
        auto)
            if [ "$permission_profile" = "shared" ]; then
                resolved_owner=none
            else
                resolved_owner="$(id -u):$(id -g)"
            fi
            ;;
        *) resolved_owner="$requested_owner" ;;
    esac

    if [ "$requested_directory_mode" = "auto" ]; then
        case "$permission_profile" in
            shared) resolved_directory_mode='a+rwX' ;;
            *) resolved_directory_mode='u+rwX,go-rwx' ;;
        esac
    else
        resolved_directory_mode="$requested_directory_mode"
    fi

    if [ "$requested_file_mode" = "auto" ]; then
        case "$permission_profile" in
            shared) resolved_file_mode='a+rwX' ;;
            *) resolved_file_mode='u+rwX,go-rwx' ;;
        esac
    else
        resolved_file_mode="$requested_file_mode"
    fi

    # find does not follow symbolic links by default. -xdev also prevents a
    # nested mount from being modified as part of the selected Codex home.
    if [ "$resolved_owner" != "none" ]; then
        run_privileged find "$directory" -xdev -type f -exec chown "$resolved_owner" {} +
        run_privileged find "$directory" -xdev -type d -exec chown "$resolved_owner" {} +
    fi
    run_privileged find "$directory" -xdev -type f -exec chmod "$resolved_file_mode" {} +
    run_privileged find "$directory" -xdev -type d -exec chmod "$resolved_directory_mode" {} +
}

ensure_volume_access() {
    directory="$1"

    if [ ! -d "$directory" ]; then
        fail "Codex volume path is not mounted or is not a directory: ${directory}"
    fi

    if [ ! -r "$directory" ] || [ ! -w "$directory" ] || [ ! -x "$directory" ]; then
        fail "Codex volume path must be readable, writable, and searchable by user $(id -un): ${directory}"
    fi
}

prepare_codespaces_home() {
    directory="$1"

    [ "$directory" = "$CODESPACES_HOME" ] || return 0
    [ ! -e "$directory" ] || return 0

    parent_directory="$(dirname "$directory")"
    if [ ! -d "$parent_directory" ]; then
        fail "Codex Codespaces storage parent is not mounted: ${parent_directory}"
    fi

    if mkdir "$directory" 2>/dev/null; then
        return 0
    fi

    run_privileged mkdir "$directory"
    run_privileged chown "$(id -u):$(id -g)" "$directory"
}

replace_symlink() {
    source_path="$1"
    target_path="$2"
    privileged="${3:-false}"

    if [ -L "$target_path" ]; then
        current_source="$(readlink "$target_path")"
        [ "$current_source" = "$source_path" ] && return 0
        if [ "$privileged" = "true" ]; then
            run_privileged ln -sfn "$source_path" "$target_path"
        else
            ln -sfn "$source_path" "$target_path"
        fi
        return 0
    fi

    if [ -e "$target_path" ]; then
        if [ "$target_path" = "$source_path" ]; then
            return 0
        fi
        if [ -d "$target_path" ] && [ -z "$(find "$target_path" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
            if [ "$privileged" = "true" ]; then
                run_privileged rmdir "$target_path"
                run_privileged ln -s "$source_path" "$target_path"
            else
                rmdir "$target_path"
                ln -s "$source_path" "$target_path"
            fi
            return 0
        fi
        warn "not replacing existing path ${target_path}; move it aside and restart the container to use the configured volume."
        return 0
    fi

    parent_path="$(dirname "$target_path")"
    if [ "$privileged" = "true" ]; then
        run_privileged mkdir -p "$parent_path"
        run_privileged ln -s "$source_path" "$target_path"
    else
        mkdir -p "$parent_path"
        ln -s "$source_path" "$target_path"
    fi
}

CODEX_HOME_PATH="$(read_option codex-home "${HOME}/.codex")"
VOLUME_PATH="$(read_option volume-path "$PER_CONTAINER_HOME")"
FIX_PERMISSIONS="$(read_option fix-permissions true)"
PERMISSIONS_OWNER="$(read_option permissions-owner auto)"
DIRECTORY_MODE="$(read_option directory-mode auto)"
FILE_MODE="$(read_option file-mode auto)"

case "$VOLUME_PATH" in
    /*) ;;
    *) fail "volumePath must be an absolute container path." ;;
esac

if [ "$VOLUME_PATH" = "$ACTIVE_HOME" ]; then
    fail "volumePath must not point to the Feature's active symlink."
fi

case "$FIX_PERMISSIONS" in
    true | 1 | yes) FIX_PERMISSIONS=true ;;
    false | 0 | no) FIX_PERMISSIONS=false ;;
    *) fail "fixPermissions must be a boolean value." ;;
esac

case "$PERMISSIONS_OWNER" in
    auto | none) ;;
    "" | -* | *:*:* | *[!A-Za-z0-9_.:-]*) fail "permissionsOwner must be auto, none, or USER[:GROUP]." ;;
esac
validate_mode_option "directoryMode" "$DIRECTORY_MODE"
validate_mode_option "fileMode" "$FILE_MODE"

if [ "${CODEX_FEATURE_BUILD_CONFIGURATION:-0}" != "1" ]; then
    prepare_codespaces_home "$VOLUME_PATH"
    if ! run_privileged test -d "$VOLUME_PATH"; then
        fail "Codex volume path is not mounted or is not a directory: ${VOLUME_PATH}"
    fi
    if [ "$FIX_PERMISSIONS" = "true" ]; then
        apply_permissions "$VOLUME_PATH" "$PERMISSIONS_OWNER" "$DIRECTORY_MODE" "$FILE_MODE"
    fi
    ensure_volume_access "$VOLUME_PATH"
fi
replace_symlink "$VOLUME_PATH" "$ACTIVE_HOME" true

if [ "$CODEX_HOME_PATH" != "$ACTIVE_HOME" ] && [ "$CODEX_HOME_PATH" != "$VOLUME_PATH" ]; then
    replace_symlink "$ACTIVE_HOME" "$CODEX_HOME_PATH" false
fi
