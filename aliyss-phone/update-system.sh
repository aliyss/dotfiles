#!/usr/bin/env bash
set -euo pipefail

# update-system.sh — update the phone's "system" layer, then apply home.
#
# There is no NixOS on the phone, so "system" means the Termux base + the
# flake's inputs (the analog of `nixos-rebuild` / `upgrade-flake` on desktop):
#   1. pkg upgrade          — Termux base packages
#   2. nix flake update     — refresh nixpkgs + home-manager inputs
#   3. update-home.sh       — rebuild + activate the aliyss-termux config
#
# The Nix binary itself is version-pinned by nix-install.sh (NIX_VERSION); bump
# it there to update Nix (`nix upgrade-nix` is unavailable — the profile is
# managed by `nix profile`).
#
# Usage:   bash update-system.sh
# Options (env vars): REPO_DIR  (default ~/dotfiles)

REPO_DIR="${REPO_DIR:-$HOME/dotfiles}"
export PATH="$HOME/.local/bin:$PATH"

log() { printf '\n\033[1;34m== %s ==\033[0m\n' "$*"; }
warn() { printf '\033[1;33m!! %s\033[0m\n' "$*" >&2; }

log "Upgrading Termux base packages"
pkg upgrade -y || warn "pkg upgrade failed (continuing)"

log "Updating flake inputs"
if [ -d "$REPO_DIR/flake" ]; then
  (cd "$REPO_DIR/flake" && nix flake update) || warn "nix flake update failed (continuing)"
else
  warn "no checkout at $REPO_DIR — skipping flake update"
fi

log "Applying home config"
exec bash "$(dirname "$0")/update-home.sh"