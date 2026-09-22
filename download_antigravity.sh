#!/bin/bash
#
# Fetch the LATEST Linux x64 Antigravity tarballs straight from the official
# download page - no manual copying of URLs.
#
# The file URLs on https://antigravity.google/download carry an unpredictable
# build id (e.g. .../2.14.0-5449404535144448/...), so there is no stable
# "latest" URL to hardcode - this script scrapes the current ones out of the
# page HTML.
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

# Note: the `|| true` on each scrape matters. Under `set -e` + `pipefail` a
# grep that matches nothing kills the script silently, before the explicit
# error messages below ever get a chance to print.

# Antigravity (agent app): storage.googleapis.com/.../antigravity-hub/.../Antigravity.tar.gz
AG_URL="$(printf '%s' "$HTML" \
    | grep -oE 'https://storage\.googleapis\.com/antigravity-public/antigravity-hub/[^"'\'' `\\]+/linux-x64/Antigravity\.tar\.gz' \
    | head -1 || true)"
# Antigravity IDE: edgedl.me.gvt1.com/.../Antigravity%20IDE.tar.gz
IDE_URL="$(printf '%s' "$HTML" \
    | grep -oE 'https://edgedl\.me\.gvt1\.com/[^"'\'' `\\]+/linux-x64/Antigravity%20IDE\.tar\.gz' \
    | head -1 || true)"

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
