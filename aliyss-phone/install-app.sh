#!/usr/bin/env bash
set -euo pipefail

# install-app.sh — build + install an Android app on the phone from the
# aliyss-android-pkgs flake input, in one step.
#
# The dotfiles flake re-exports the android-pkgs package set (flake/flake.nix),
# so every pinned app-id is a buildable derivation. Accepts the dotted app-id
# or the dashed flake attr (dots are auto-converted):
#   bash install-app.sh com.darkempire78.opencalculator
#   bash install-app.sh org-videolan-vlc com.spotify.music   # several at once
#
# Flow per app:
#   1. nix build .#<app-id>        (fetches the pinned APK, like `nix flake check`)
#   2. resolve the built APK's host path — the `result`/out-link symlinks point
#      into the chroot's /nix, which Android cannot read; the real store is at
#      ~/.nix/nix (bind-mounted at /nix inside the chroot)
#   3. pm install -r, trying the Termux user first and falling back to root
#      (su -c 'pm install') — same fallback as android-pkgs' scripts/install.sh.
#
# Requires: the aliyss-android-pkgs flake input (already in flake.lock) and
# root (KernelSU/Magisk) for the pm install fallback.
#
# Usage:   bash install-app.sh <app-id> [<app-id> ...]
# Options (env vars):
#   REPO_DIR   path to the dotfiles checkout  (default ~/.config)
#   PULL       pull the repo first            (default 0)

REPO_DIR="${REPO_DIR:-$HOME/.config}"
PULL="${PULL:-0}"
export PATH="$HOME/.local/bin:$PATH"

log() { printf '\n\033[1;34m== %s ==\033[0m\n' "$*"; }
warn() { printf '\033[1;33m!! %s\033[0m\n' "$*" >&2; }

[ "$#" -ge 1 ] || {
  echo "usage: bash install-app.sh <app-id> [<app-id> ...]" >&2
  exit 1
}

if [ ! -f "$REPO_DIR/flake/flake.nix" ]; then
  echo "dotfiles checkout not found at $REPO_DIR" >&2
  echo "bootstrap it first: bash <(curl -fsSL https://raw.githubusercontent.com/aliyss/dotfiles/master/aliyss-phone/nix-install.sh)" >&2
  exit 1
fi

if [ "$PULL" = "1" ] && [ -d "$REPO_DIR/.git" ]; then
  log "Pulling latest dotfiles"
  git -C "$REPO_DIR" pull --ff-only || echo "  (pull failed — continuing)" >&2
fi

# --- app-id <-> flake attr -----------------------------------------------
# Mirror android-pkgs' pkgs/default.nix sanitizeName: dots -> dashes, and
# prefix "pkg-" for app-ids that start with a digit (illegal Nix attr names).
# Android package names never contain dashes, so the reverse (dashes -> dots,
# stripping the pkg- prefix) always recovers the real app-id.
toAttr() {
  local s="${1//./-}"
  case "$s" in
    [0-9]*) echo "pkg-$s" ;;
    *) echo "$s" ;;
  esac
}
toAppId() {
  local s="${1#pkg-}"
  echo "${s//-/}"
}

install_one() {
  local input="$1"
  local attr app_id
  if [[ "$input" == *.* ]]; then
    app_id="$input"
    attr="$(toAttr "$input")"
  else
    attr="$input"
    app_id="$(toAppId "$input")"
  fi

  mkdir -p "$HOME/.cache/nix/out"

  log "Building $app_id (flake attr: $attr)"
  (
    cd "$REPO_DIR/flake"
    nix build ".#$attr" --out-link "$HOME/.cache/nix/out/$attr"
  )

  # Map the chroot store path (/nix/store/...) to the host-visible store
  # (~/.nix/nix/store/...) so Android's pm can actually open the file.
  local chroot_path
  chroot_path="$(cd "$REPO_DIR/flake" && nix path-info ".#$attr")"
  local host_apk="$HOME/.nix/nix/${chroot_path#/nix/}"

  if [ ! -f "$host_apk" ]; then
    echo "built output not found at $host_apk" >&2
    exit 1
  fi
  # An APK is a zip archive — sanity-check the magic bytes before installing.
  if [ "$(head -c 2 "$host_apk")" != "PK" ]; then
    warn "$app_id built, but $host_apk does not look like an APK (zip) — skipping install"
    return 1
  fi

  log "Installing $app_id ($(du -h "$host_apk" | cut -f1))"
  if ! pm install -r "$host_apk" 2>/dev/null; then
    echo "  (user pm install denied — retrying as root)"
    su -c "pm install -r '$host_apk'"
  fi

  if pm list packages 2>/dev/null | grep -qx "package:$app_id"; then
    echo "  installed: $app_id"
  else
    warn "$app_id installed but not found in 'pm list packages'?"
  fi
}

for app in "$@"; do
  install_one "$app"
done

log "Done."
