#!/usr/bin/env bash
set -euo pipefail

# update-system.sh — update the phone's "system" layer, then apply home.
#
# There is no NixOS on the phone, so "system" mirrors the desktop's
# `update-system` (flake/update-system): it only *applies* the current flake.
#   1. pkg upgrade          — Termux base packages (analog of nixos-rebuild's
#                            system packages; safe to always run)
#   2. update-home.sh       — rebuild + activate the aliyss-termux config from
#                            the current flake.lock (no `nix flake update` here;
#                            run `upgrade-flake` explicitly when you want new
#                            inputs, same as desktop)
#
# Use `upgrade-flake` (alias: `nix flake update --flake ~/.config/flake`) to
# bump nixpkgs/home-manager, then `update-home` or `update-system` to apply.
#
# The Nix binary itself is version-pinned by nix-install.sh (NIX_VERSION); bump
# it there to update Nix (`nix upgrade-nix` is unavailable — the profile is
# managed by `nix profile`).
#
# Usage:   bash update-system.sh
# Options (env vars): REPO_DIR  (default ~/.config)

REPO_DIR="${REPO_DIR:-$HOME/.config}"
export PATH="$HOME/.local/bin:$PATH"

log() { printf '\n\033[1;34m== %s ==\033[0m\n' "$*"; }
warn() { printf '\033[1;33m!! %s\033[0m\n' "$*" >&2; }

log "Upgrading Termux base packages"
pkg upgrade -y || warn "pkg upgrade failed (continuing)"

log "Applying home config (current flake.lock; use upgrade-flake to bump inputs)"
exec bash "$(dirname "$0")/update-home.sh"