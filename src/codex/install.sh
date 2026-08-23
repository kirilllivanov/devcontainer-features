#!/bin/sh
set -eu

SOURCE_DIR="$(CDPATH='' cd -- "$(dirname "$0")" && pwd)"
FEATURE_DIR="${CODEX_FEATURE_DIR:-/usr/local/share/codex-feature}"
CLI_ROOT="${CODEX_FEATURE_CLI_ROOT:-/usr/local/lib/codex-cli}"
CLI_BIN_LINK="${CODEX_FEATURE_BIN_LINK:-/usr/local/bin/codex}"
STORAGE_ROOT="${CODEX_FEATURE_STORAGE_ROOT:-/run/codex}"
PER_CONTAINER_HOME="${STORAGE_ROOT}/per-container"
SHARED_HOME="${STORAGE_ROOT}/shared"
ACTIVE_HOME="${STORAGE_ROOT}/active"

CLI_VERSION="${CLIVERSION:-latest}"
EXTENSION_VERSION="${EXTENSIONVERSION:-latest}"
VOLUME_PATH="${VOLUMEPATH:-${STORAGE_ROOT}/per-container}"
FIX_PERMISSIONS="${FIXPERMISSIONS:-true}"
PERMISSIONS_OWNER="${PERMISSIONSOWNER:-auto}"
DIRECTORY_MODE="${DIRECTORYMODE:-auto}"
FILE_MODE="${FILEMODE:-auto}"

fail() {
    printf 'Codex feature: %s\n' "$1" >&2
    exit 1
}

install_download_dependencies() {
    if command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1; then
        return 0
    fi

    printf 'Codex feature: installing curl and CA certificates\n'
    if command -v apt-get >/dev/null 2>&1; then
        export DEBIAN_FRONTEND=noninteractive
        if [ -z "$(find /var/lib/apt/lists -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
            apt-get update -y
        fi
        apt-get install -y --no-install-recommends curl ca-certificates
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache curl ca-certificates
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y curl ca-certificates
        dnf clean all
    elif command -v microdnf >/dev/null 2>&1; then
        microdnf install -y curl ca-certificates
        microdnf clean all
    elif command -v yum >/dev/null 2>&1; then
        yum install -y curl ca-certificates
        yum clean all
    elif command -v tdnf >/dev/null 2>&1; then
        tdnf install -y curl ca-certificates
        tdnf clean all
    else
        fail "curl or wget is required, and no supported package manager was found."
    fi
}

contains_newline() {
    case "$1" in
        *'
'*) return 0 ;;
        *) return 1 ;;
    esac
}

validate_version_option() {
    option_name="$1"
    option_value="$2"

    case "$option_value" in
        latest | none) return 0 ;;
        "") fail "${option_name} must not be empty." ;;
        *[!A-Za-z0-9._+-]*) fail "${option_name} contains unsupported characters: ${option_value}" ;;
    esac
}

validate_single_line_option() {
    option_name="$1"
    option_value="$2"
    if contains_newline "$option_value"; then
        fail "${option_name} must be a single-line value."
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

write_option() {
    option_name="$1"
    option_value="$2"
    printf '%s' "$option_value" >"${FEATURE_DIR}/${option_name}"
    chmod 0644 "${FEATURE_DIR}/${option_name}"
}

install_cli() {
    [ "$CLI_VERSION" != "none" ] || return 0

    install_download_dependencies
    installer_file="$(mktemp)"
    trap 'rm -f "$installer_file"' EXIT HUP INT TERM
    installer_url="${CODEX_INSTALLER_URL:-https://chatgpt.com/codex/install.sh}"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$installer_url" -o "$installer_file"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$installer_file" "$installer_url"
    else
        fail "curl or wget is required to download the official Codex standalone installer."
    fi

    mkdir -p "${CLI_ROOT}/bin" "${CLI_ROOT}/state"
    CODEX_HOME="${CLI_ROOT}/state" \
        CODEX_INSTALL_DIR="${CLI_ROOT}/bin" \
        CODEX_NON_INTERACTIVE=true \
        sh "$installer_file" --release "$CLI_VERSION"

    [ -x "${CLI_ROOT}/bin/codex" ] || fail "the Codex standalone installer did not create the expected executable."
    mkdir -p "$(dirname "$CLI_BIN_LINK")"
    ln -sfn "${CLI_ROOT}/bin/codex" "$CLI_BIN_LINK"

    trap - EXIT HUP INT TERM
    rm -f "$installer_file"
}

validate_version_option "cliVersion" "$CLI_VERSION"
validate_version_option "extensionVersion" "$EXTENSION_VERSION"
validate_single_line_option "volumePath" "$VOLUME_PATH"
validate_single_line_option "permissionsOwner" "$PERMISSIONS_OWNER"
validate_mode_option "directoryMode" "$DIRECTORY_MODE"
validate_mode_option "fileMode" "$FILE_MODE"

case "$VOLUME_PATH" in
    /*) ;;
    *) fail "volumePath must be an absolute container path." ;;
esac

case "$FIX_PERMISSIONS" in
    true | false | 1 | 0 | yes | no) ;;
    *) fail "fixPermissions must be a boolean value." ;;
esac

case "$PERMISSIONS_OWNER" in
    auto | none) ;;
    "" | -* | *:*:* | *[!A-Za-z0-9_.:-]*) fail "permissionsOwner must be auto, none, or USER[:GROUP]." ;;
esac

if [ "$VOLUME_PATH" = "$ACTIVE_HOME" ]; then
    fail "volumePath must not point to the Feature's active symlink."
fi

REMOTE_HOME="${_REMOTE_USER_HOME:-${_CONTAINER_USER_HOME:-/root}}"
RESOLVED_CODEX_HOME="${REMOTE_HOME}/.codex"
printf 'Activating the Codex feature\n'
printf 'Codex CLI version: %s\n' "$CLI_VERSION"
printf 'VS Code extension version: %s\n' "$EXTENSION_VERSION"
printf 'Codex home mount point: %s\n' "$RESOLVED_CODEX_HOME"

mkdir -p "$FEATURE_DIR" "$PER_CONTAINER_HOME" "$SHARED_HOME"
install -m 0755 "${SOURCE_DIR}/configure.sh" "${FEATURE_DIR}/configure.sh"
install -m 0755 "${SOURCE_DIR}/install-extension.sh" "${FEATURE_DIR}/install-extension.sh"

write_option "codex-home" "$RESOLVED_CODEX_HOME"
write_option "extension-version" "$EXTENSION_VERSION"
write_option "volume-path" "$VOLUME_PATH"
write_option "fix-permissions" "$FIX_PERMISSIONS"
write_option "permissions-owner" "$PERMISSIONS_OWNER"
write_option "directory-mode" "$DIRECTORY_MODE"
write_option "file-mode" "$FILE_MODE"

ln -sfn "$VOLUME_PATH" "$ACTIVE_HOME"

install_cli

# Configure the image-layer symlinks now. The lifecycle hook repeats this after
# volumes and optional bind mounts have been attached to the running container.
CODEX_FEATURE_BUILD_CONFIGURATION=1 \
    CODEX_FEATURE_DIR="$FEATURE_DIR" \
    CODEX_FEATURE_STORAGE_ROOT="$STORAGE_ROOT" \
    "${FEATURE_DIR}/configure.sh"

printf 'Codex feature installation complete.\n'
