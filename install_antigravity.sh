#!/bin/bash
#
# Install Google Antigravity + Antigravity IDE from the downloaded .tar.gz files.
# Mirrors the /opt-based install style used for Cursor.
#
# Usage:  sudo bash install_antigravity.sh
#
set -euo pipefail

# --- config (override any of these via environment variables) --------------
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

AG_TAR="$SRC_DIR/antigravity.tar.gz"          # Antigravity (agent desktop app)
IDE_TAR="$SRC_DIR/antigravity-ide.tar.gz"     # Antigravity IDE (VS Code fork)

PREFIX="${PREFIX:-/opt}"                        # base install dir
AG_DIR="${AG_DIR:-$PREFIX/antigravity}"        # install target: agent app
IDE_DIR="${IDE_DIR:-$PREFIX/antigravity-ide}"  # install target: IDE

APP_DIR="${APP_DIR:-/usr/share/applications}"  # .desktop launchers
BIN_DIR="${BIN_DIR:-/usr/local/bin}"           # CLI symlinks
# ---------------------------------------------------------------------------

if [ "$(id -u)" -ne 0 ]; then
    echo "This installer writes to $PREFIX, $BIN_DIR and $APP_DIR, and needs root" >&2
    echo "to set the chrome-sandbox setuid bit. Please run it with sudo:" >&2
    echo "    sudo bash $0" >&2
    echo "Locations are configurable, e.g.:  sudo PREFIX=/usr/local/lib bash $0" >&2
    exit 1
fi

for f in "$AG_TAR" "$IDE_TAR" "$SRC_DIR/antigravity.png"; do
    [ -f "$f" ] || { echo "Missing required file: $f" >&2; exit 1; }
done

echo "==> Installing Antigravity (agent app) -> $AG_DIR"
rm -rf /opt/Antigravity-x64 "$AG_DIR"
tar -xzf "$AG_TAR" -C /opt
mv /opt/Antigravity-x64 "$AG_DIR"

echo "==> Installing Antigravity IDE -> $IDE_DIR"
rm -rf "/opt/Antigravity IDE" "$IDE_DIR"
tar -xzf "$IDE_TAR" -C /opt
mv "/opt/Antigravity IDE" "$IDE_DIR"

# --- Electron chrome-sandbox needs root:root + setuid, or the app will
#     refuse to start ("SUID sandbox helper ... not configured correctly").
echo "==> Fixing chrome-sandbox permissions"
for d in "$AG_DIR" "$IDE_DIR"; do
    if [ -f "$d/chrome-sandbox" ]; then
        chown root:root "$d/chrome-sandbox"
        chmod 4755 "$d/chrome-sandbox"
    fi
done

# --- icons ---------------------------------------------------------------
# The IDE ships a real icon file; the agent app keeps its icon inside app.asar,
# so we use antigravity.png (extracted from the asar at setup time) instead.
echo "==> Installing icons"
cp "$SRC_DIR/antigravity.png" "$AG_DIR/icon.png"
AG_ICON="$AG_DIR/icon.png"
IDE_ICON="$IDE_DIR/resources/app/resources/linux/code.png"

# --- CLI symlinks --------------------------------------------------------
echo "==> Creating CLI symlinks in $BIN_DIR"
ln -sf "$AG_DIR/antigravity"       "$BIN_DIR/antigravity"
ln -sf "$IDE_DIR/bin/antigravity-ide" "$BIN_DIR/antigravity-ide"

# --- desktop entries -----------------------------------------------------
echo "==> Creating desktop launchers in $APP_DIR"
cat > "$APP_DIR/antigravity.desktop" <<EOL
[Desktop Entry]
Name=Antigravity
GenericName=AI Agent Manager
Comment=Antigravity - Agentic Desktop Application
Exec=$AG_DIR/antigravity %U
Icon=$AG_ICON
Type=Application
StartupNotify=true
StartupWMClass=Antigravity
Categories=Development;
EOL

cat > "$APP_DIR/antigravity-ide.desktop" <<EOL
[Desktop Entry]
Name=Antigravity IDE
GenericName=Text Editor
Comment=Antigravity IDE - Agentic code editor
Exec=$IDE_DIR/antigravity-ide %F
Icon=$IDE_ICON
Type=Application
StartupNotify=true
StartupWMClass=antigravity-ide
Categories=TextEditor;Development;IDE;
MimeType=text/plain;inode/directory;
Actions=new-empty-window;
Keywords=antigravity;editor;

[Desktop Action new-empty-window]
Name=New Empty Window
Exec=$IDE_DIR/antigravity-ide --new-window %F
Icon=$IDE_ICON
EOL

# refresh the application database if the tool is available
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APP_DIR" || true

echo
echo "Done."
echo "  Antigravity      -> $AG_DIR  (cli: antigravity)"
echo "  Antigravity IDE  -> $IDE_DIR (cli: antigravity-ide)"
echo "Launch from your application menu, or run 'antigravity' / 'antigravity-ide'."
