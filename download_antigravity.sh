#!/bin/bash
#
# Fetch the LATEST Linux x64 Antigravity tarballs straight from the official
# download page - no manual copying of URLs.
#
# The download page (https://antigravity.google/download) is an Angular SPA and
# the real file URLs are baked into its main-*.js bundle, with an unpredictable
# build id in each URL (e.g. .../2.2.1-5287492581195776/...). So there is no
# stable "latest" URL to hardcode - this script scrapes the current ones.
#
# Usage:
#   bash download_antigravity.sh            # download both tarballs here
#   bash download_antigravity.sh --check    # just print the URLs, don't download
#
set -euo pipefail

DEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE="https://antigravity.google"
CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1

echo "==> Reading $BASE/download"
HTML="$(curl -fsSL --compressed "$BASE/download")"

# Find the hashed Angular main bundle referenced by the page.
MAIN_JS="$(printf '%s' "$HTML" | grep -oE 'main-[A-Za-z0-9]+\.js' | head -1)"
[ -n "$MAIN_JS" ] || { echo "ERROR: could not find the main-*.js bundle on the page." >&2; exit 1; }
echo "    bundle: $MAIN_JS"

JS="$(curl -fsSL --compressed "$BASE/$MAIN_JS")"

# Antigravity (agent app): storage.googleapis.com/.../antigravity-hub/.../Antigravity.tar.gz
AG_URL="$(printf '%s' "$JS" \
    | grep -oE 'https://storage\.googleapis\.com/antigravity-public/antigravity-hub/[^"'\'' `]+/linux-x64/Antigravity\.tar\.gz' \
    | head -1)"
# Antigravity IDE: edgedl.me.gvt1.com/.../Antigravity%20IDE.tar.gz
IDE_URL="$(printf '%s' "$JS" \
    | grep -oE 'https://edgedl\.me\.gvt1\.com/[^"'\'' `]+/linux-x64/Antigravity%20IDE\.tar\.gz' \
    | head -1)"

[ -n "$AG_URL" ]  || { echo "ERROR: could not extract the Antigravity URL (page layout may have changed)." >&2; exit 1; }
[ -n "$IDE_URL" ] || { echo "ERROR: could not extract the Antigravity IDE URL (page layout may have changed)." >&2; exit 1; }

AG_VER="$(printf '%s'  "$AG_URL"  | grep -oE 'antigravity-hub/[0-9.]+' | cut -d/ -f2)"
IDE_VER="$(printf '%s' "$IDE_URL" | grep -oE 'stable/[0-9.]+'          | cut -d/ -f2)"

echo "==> Antigravity      v${AG_VER}:  $AG_URL"
echo "==> Antigravity IDE  v${IDE_VER}: $IDE_URL"

if [ "$CHECK_ONLY" -eq 1 ]; then
    echo "(--check: not downloading)"
    exit 0
fi

echo "==> Downloading into $DEST_DIR (this is ~400 MB total)"
curl -fL --progress-bar "$AG_URL"  -o "$DEST_DIR/antigravity.tar.gz"
curl -fL --progress-bar "$IDE_URL" -o "$DEST_DIR/antigravity-ide.tar.gz"

echo
echo "Done. Next:  sudo bash $DEST_DIR/install_antigravity.sh"
