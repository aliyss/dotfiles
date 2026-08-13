#!/usr/bin/env bash
set -euo pipefail

# update-home.sh — build + activate the phone's home-manager config from the
# dotfiles flake. Run on the phone (any cwd); requires nix-install.sh to have
# bootstrapped Nix first.
#
# Applies the shared central theme (flake/lib/theme.nix) to:
#   ~/.termux/colors.properties      (Termux colors)
#   ~/.config/fish/config.fish       (fish config)
# plus the phone home packages.
#
# Usage:   bash update-home.sh
# Options (env vars):
#   REPO_DIR   path to the dotfiles checkout  (default ~/.config)
#   PULL       pull the repo first            (default 1)

REPO_DIR="${REPO_DIR:-$HOME/.config}"
PULL="${PULL:-1}"
export PATH="$HOME/.local/bin:$PATH"

log() { printf '\n\033[1;34m== %s ==\033[0m\n' "$*"; }

if [ ! -f "$REPO_DIR/flake/flake.nix" ]; then
  echo "dotfiles checkout not found at $REPO_DIR" >&2
  echo "bootstrap it first: bash <(curl -fsSL https://raw.githubusercontent.com/aliyss/dotfiles/master/aliyss-phone/nix-install.sh)" >&2
  exit 1
fi

if [ "$PULL" = "1" ] && [ -d "$REPO_DIR/.git" ]; then
  log "Pulling latest dotfiles"
  git -C "$REPO_DIR" pull --ff-only || echo "  (pull failed — switching anyway)" >&2
fi

log "Switching home-manager config: aliyss-termux"
if [ -x "$HOME/.nix-profile/bin/home-manager" ]; then
  (
    cd "$REPO_DIR/flake"
    home-manager switch --flake ".#aliyss-termux" "$@"
  )
else
  # First switch: the profile doesn't have home-manager yet (the activation
  # installs its own `home-manager-path`), so run it out of nixpkgs.
  (
    cd "$REPO_DIR/flake"
    nix run nixpkgs#home-manager -- switch --flake ".#aliyss-termux" "$@"
  )
fi

log "Reloading Termux colors"
termux-reload-settings 2>/dev/null || true

log "Wrapping installed tools for the Termux shell"
bash "$(dirname "$0")/ensure-nix-wrappers.sh"

log "Done. Phone config applied."