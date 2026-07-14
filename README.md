# Google Antigravity - Linux installer

Scripts to download, install, and uninstall **Google Antigravity** and the
**Antigravity IDE** on Linux from the official `.tar.gz` builds. They ship as
extract-and-run Electron / VS Code bundles (unlike Cursor's single AppImage),
so these scripts place them under `/opt`, wire up `chrome-sandbox`, and create
menu launchers + CLI symlinks.

| App | Product | Installs to (default) | CLI |
|-----|---------|-----------------------|-----|
| Antigravity | Agentic desktop app | `/opt/antigravity` | `antigravity` |
| Antigravity IDE | VS Code fork editor | `/opt/antigravity-ide` | `antigravity-ide` |

> **Tested on: Ubuntu Linux (x86_64) only.** These scripts download the
> `linux-x64` builds and assume a Debian/Ubuntu-style desktop (`/opt`,
> `/usr/share/applications`, `update-desktop-database`). They may work on other
> Debian derivatives but are untested there, and do **not** support macOS,
> Windows, or ARM. Requires `bash`, `curl`, `tar`, and `sudo`.

## Quickstart

```bash
git clone <your-repo-url> antigravity-install
cd antigravity-install

bash download_antigravity.sh          # fetch the latest tarballs into this folder
sudo bash install_antigravity.sh      # install to /opt + menu launchers + CLIs
```

The `.tar.gz` files are **not** committed (they are ~400 MB, over GitHub's
100 MB limit) - `download_antigravity.sh` fetches them.

## Download (get the latest, automatically)

```bash
bash download_antigravity.sh          # download both latest tarballs here
bash download_antigravity.sh --check  # just print the current URLs/versions, no download
```

Why a scraper and not a fixed URL: the download page is an Angular SPA and each
file URL embeds an unpredictable build id (e.g. `.../2.2.1-5287492581195776/...`)
that changes every release - there is no stable "latest" link to hardcode (unlike
Cursor's download API). The script reads the current URLs off the page's JS bundle,
so it always grabs the latest. If Google restructures the page it fails loudly, and
you can download manually from https://antigravity.google/download instead.

## Install

```bash
sudo bash install_antigravity.sh
```

What it does:
- extracts each tarball to `/opt` (as `/opt/antigravity` and `/opt/antigravity-ide`)
- sets `chrome-sandbox` to `root:root` + `4755` (required, or Electron won't start)
- installs the app icons and `.desktop` menu launchers
- symlinks the CLIs into `/usr/local/bin`

Then launch from the application menu, or:

```bash
antigravity           # agent desktop app
antigravity-ide .     # open current folder in the IDE
```

## Customising install locations

Every target path is an environment variable with a sensible default. Override
any of them (root is still required, to set the sandbox setuid bit):

| Variable | Default | Purpose |
|----------|---------|---------|
| `PREFIX` | `/opt` | base install dir |
| `AG_DIR` | `$PREFIX/antigravity` | Antigravity app dir |
| `IDE_DIR` | `$PREFIX/antigravity-ide` | Antigravity IDE dir |
| `BIN_DIR` | `/usr/local/bin` | CLI symlinks |
| `APP_DIR` | `/usr/share/applications` | `.desktop` launchers |

```bash
sudo PREFIX=/usr/local/lib bash install_antigravity.sh
```

The download location is always this repo directory (wherever you cloned it) -
no configuration needed. Use the **same** overrides when uninstalling.

## Uninstall

```bash
sudo bash uninstall_antigravity.sh
```

Removes the apps, symlinks and launchers. User data (`~/.antigravity-ide`) is
left in place.

## Upgrade

Fetch the latest, then reinstall (the installer wipes and re-extracts each
target dir):

```bash
bash download_antigravity.sh
sudo bash install_antigravity.sh
```

## Notes

- `/opt/antigravity/antigravity` and `/opt/antigravity-ide/antigravity-ide` are the
  GUI (Electron) binaries; `/opt/antigravity-ide/bin/antigravity-ide` is the
  `code`-style CLI launcher (that's what the `antigravity-ide` symlink points at).
- If the app fails to start on the sandbox helper, verify
  `ls -l /opt/antigravity/chrome-sandbox` shows `-rwsr-xr-x root root`.
  As a fallback you can run with `--no-sandbox`.
- `antigravity.png` is the 512x512 agent-app icon (its icon lives inside the
  app's `app.asar`, so it is bundled here for the launcher). The IDE uses its
  own on-disk icon.

## Disclaimer

Antigravity and the Antigravity IDE are Google products; this repo only
automates downloading and installing the official Linux builds. It is not
affiliated with or endorsed by Google.
