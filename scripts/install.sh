#!/bin/bash
# Build the reviewed checkout and install a complete, locally signed app.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DESTINATION="$HOME/Applications"
REPLACE=0
usage() {
    cat <<'HELP'
Usage: ./scripts/install.sh [--destination DIRECTORY] [--replace]

Builds this checkout and installs Specter.app in ~/Applications by default.
Requires Apple silicon, macOS 14+, and full Xcode with Swift 6 and Metal tools.
Quit Specter before installing. --replace keeps the old app as a sibling backup.
No sudo, shell configuration changes, or automatic app launch.
HELP
}
fail() { printf 'Specter install: %s\n' "$*" >&2; exit 1; }
while [[ $# -gt 0 ]]; do
    case "$1" in
        --destination)
            [[ $# -ge 2 && -n "$2" && "$2" != --* ]] || fail '--destination requires a directory.'
            DESTINATION="$2"; shift 2 ;;
        --replace) REPLACE=1; shift ;;
        --help|-h) usage; exit 0 ;;
        *) usage >&2; fail "Unknown option: $1" ;;
    esac
done
[[ "$(uname -s)" == Darwin ]] || fail 'macOS is required.'
[[ "$(uname -m)" == arm64 ]] || fail 'Run in a native Apple silicon terminal (not Rosetta).'
OS_VERSION="$(sw_vers -productVersion)"
[[ "${OS_VERSION%%.*}" -ge 14 ]] || fail 'macOS 14 or later is required.'
[[ "$EUID" -ne 0 ]] || fail 'Run as your regular user, without sudo.'
xcodebuild -version >/dev/null 2>&1 || fail 'Install full Xcode, open it, and finish component setup.'
xcrun --find swift >/dev/null 2>&1 || fail 'Select the Xcode Swift toolchain.'
xcrun --find metal >/dev/null 2>&1 || fail 'Install the Metal tools in Xcode.'
SWIFT_VERSION="$(xcrun swift --version 2>&1)"
[[ "$SWIFT_VERSION" =~ Swift\ version\ ([0-9]+) ]] || fail 'Cannot determine the Swift version.'
[[ "${BASH_REMATCH[1]}" -ge 6 ]] || fail 'Swift 6 or later is required.'
mkdir -p "$DESTINATION"
DESTINATION="$(cd "$DESTINATION" && pwd -P)"
APP="$DESTINATION/Specter.app"
check_running() {
    if [[ -f "$APP/Contents/MacOS/Specter" ]] && /usr/sbin/lsof -t "$APP/Contents/MacOS/Specter" >/dev/null 2>&1; then
        fail 'Save your work and quit the installed Specter app, then retry from another terminal.'
    fi
}
check_destination() {
    check_running
    [[ ! -L "$APP" ]] || fail "Refusing to replace a symbolic link: $APP"
    if [[ -e "$APP" ]]; then
        [[ "$REPLACE" -eq 1 ]] || fail "Already installed at $APP. To update, quit Specter and rerun with --replace."
        [[ -d "$APP" ]] || fail "Not an app directory: $APP"
        local identifier
        identifier="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Contents/Info.plist" 2>/dev/null)" || fail 'Existing app has no readable bundle identifier.'
        [[ "$identifier" == app.specter.terminal ]] || fail 'Existing app is not a Specter bundle; move it yourself before installing.'
    fi
}
LOCK="$DESTINATION/.specter-install.lock"
mkdir "$LOCK" 2>/dev/null || fail "Installation is locked: $LOCK. If no installer is running, remove that empty directory and retry."
STAGE=''
BACKUP=''
INSTALLED=0
cleanup() {
    local result=$?
    trap - EXIT
    if [[ "$INSTALLED" -eq 0 && -n "$BACKUP" && ! -e "$APP" ]]; then
        mv "$BACKUP" "$APP" || printf 'Restore your previous app from %s\n' "$BACKUP" >&2
    fi
    if [[ -n "$STAGE" ]]; then rm -rf "$STAGE"; fi
    rmdir "$LOCK"
    exit "$result"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
check_destination
STAGE="$(mktemp -d "$DESTINATION/.specter-install.XXXXXX")"
printf 'Building source from %s\nInstalling in %s\n' "$ROOT" "$DESTINATION"
SPECTER_APP_OUTPUT="$STAGE/Specter.app" "$ROOT/scripts/build-app.sh"
codesign --verify --deep --strict --verbose=2 "$STAGE/Specter.app"
# Recheck after the build: it may have taken several minutes.
check_destination
if [[ -e "$APP" ]]; then
    BACKUP="$DESTINATION/Specter.backup.$(date +%Y%m%d-%H%M%S).$$.app"
    [[ ! -e "$BACKUP" && ! -L "$BACKUP" ]] || fail "Backup path already exists: $BACKUP"
    mv "$APP" "$BACKUP"
fi
mv "$STAGE/Specter.app" "$APP"
INSTALLED=1
printf '\nInstalled %s\n' "$APP"
if [[ -n "$BACKUP" ]]; then printf 'Previous app kept at %s\n' "$BACKUP"; fi
printf 'Open with: open %q\n' "$APP"
