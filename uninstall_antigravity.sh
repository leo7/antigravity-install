#!/bin/bash
#
# Remove Antigravity + Antigravity IDE installed by install_antigravity.sh.
# Usage:  sudo bash uninstall_antigravity.sh
#
# NOTE: this removes the applications only. Your user config/data
#       (~/.antigravity-ide and related dirs) is left untouched.
#
set -euo pipefail

# Must match whatever was used at install time (override to match custom installs).
PREFIX="${PREFIX:-/opt}"
AG_DIR="${AG_DIR:-$PREFIX/antigravity}"
IDE_DIR="${IDE_DIR:-$PREFIX/antigravity-ide}"
APP_DIR="${APP_DIR:-/usr/share/applications}"
BIN_DIR="${BIN_DIR:-/usr/local/bin}"

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run with sudo:  sudo bash $0" >&2
    exit 1
fi

echo "==> Removing installed apps"
rm -rf "$AG_DIR" "$IDE_DIR"

echo "==> Removing CLI symlinks"
rm -f "$BIN_DIR/antigravity" "$BIN_DIR/antigravity-ide"

echo "==> Removing desktop launchers"
rm -f "$APP_DIR/antigravity.desktop" "$APP_DIR/antigravity-ide.desktop"

command -v update-desktop-database >/dev/null 2>&1 && \
    update-desktop-database "$APP_DIR" || true

echo "Done. (User data in ~/.antigravity-ide was NOT removed.)"
