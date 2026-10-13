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

# Installed versions, looked up in the same dirs install_antigravity.sh uses
# (honouring the same PREFIX / AG_DIR / IDE_DIR overrides). Empty if not installed.
PREFIX="${PREFIX:-/opt}"
AG_DIR="${AG_DIR:-$PREFIX/antigravity}"
IDE_DIR="${IDE_DIR:-$PREFIX/antigravity-ide}"
# The agent app's package.json sits uncompressed inside app.asar, with the
# version on the line after productName.
AG_INSTALLED="$(grep -a -A1 '"productName": "Antigravity"' "$AG_DIR/resources/app.asar" 2>/dev/null \
    | grep -oE '"version": *"[0-9.]+"' | grep -oE '[0-9][0-9.]*' || true)"
# The IDE's own version is ideVersion in product.json; `antigravity-ide
# --version` prints the underlying VS Code version instead.
IDE_INSTALLED="$(grep -oE '"ideVersion": *"[0-9.]+"' "$IDE_DIR/resources/app/product.json" 2>/dev/null \
    | grep -oE '[0-9][0-9.]*' || true)"

echo "==> Antigravity      v${AG_VER} (installed: ${AG_INSTALLED:-none}):  $AG_URL"
echo "==> Antigravity IDE  v${IDE_VER} (installed: ${IDE_INSTALLED:-none}): $IDE_URL"

if [ "$CHECK_ONLY" -eq 1 ]; then
    echo "(--check: not downloading)"
    exit 0
fi

# Succeeds when the tarball should be downloaded. If the installed copy is
# already at or past the latest (the agent app self-updates, so it can be
# ahead of the page), ask first and default to No.
should_download() {
    local name="$1" latest="$2" installed="$3" ans=""
    [ -n "$installed" ] || return 0
    [ "$(printf '%s\n%s\n' "$latest" "$installed" | sort -V | tail -1)" = "$installed" ] || return 0
    read -r -p "==> $name v$installed is installed (latest is v$latest). Download anyway? [y/N] " ans || true
    [[ "$ans" =~ ^[Yy] ]]
}

DOWNLOADED=0
if should_download "Antigravity" "$AG_VER" "$AG_INSTALLED"; then
    echo "==> Downloading Antigravity into $DEST_DIR (~180 MB)"
    curl -fL --progress-bar "$AG_URL" -o "$DEST_DIR/antigravity.tar.gz"
    DOWNLOADED=1
fi
if should_download "Antigravity IDE" "$IDE_VER" "$IDE_INSTALLED"; then
    echo "==> Downloading Antigravity IDE into $DEST_DIR (~240 MB)"
    curl -fL --progress-bar "$IDE_URL" -o "$DEST_DIR/antigravity-ide.tar.gz"
    DOWNLOADED=1
fi

if [ "$DOWNLOADED" -eq 0 ]; then
    echo
    echo "Nothing downloaded - everything installed is already up to date."
    exit 0
fi

echo
echo "Done. Next:  sudo bash $DEST_DIR/install_antigravity.sh"
