#!/usr/bin/env bash
set -euo pipefail

# ensure-nix-wrappers.sh — make every tool installed via the flake
# (~/.nix-profile/bin) available from the normal Termux shell.
#
# The Nix store (~/.nix/nix) is only visible inside the chroot, and the glibc
# binaries cannot run under Termux's bionic libc, so each tool gets a
# `~/.local/bin/<name>` symlink to the `nix` wrapper script, which
# transparently runs the real binary via `~/.nix/bin/nix-chroot`.
#
# Run automatically by update-home.sh after every switch so newly added
# home.packages get wrapped too. Idempotent.

NIX_CHROOT="${NIX_CHROOT:-$HOME/.nix/bin/nix-chroot}"
WRAP_DIR="${WRAP_DIR:-$HOME/.local/bin}"

log() { printf '\n\033[1;34m== %s ==\033[0m\n' "$*"; }

mkdir -p "$WRAP_DIR"
export WRAP_DIR

log "Wrapping home-manager tools for the Termux shell"
"$NIX_CHROOT" /bin/sh -c '
  for tool in "$HOME/.nix-profile/bin"/*; do
    [ -e "$tool" ] || continue
    name=$(basename "$tool")
    case "$name" in
      # nix* / home-manager already have explicit wrappers in ~/.local/bin
      nix | home-manager | nix-*) continue ;;
      # man-db internals are a home-manager dependency, not user packages
      man | mandb | apropos | whatis | accessdb | catman | lexgrog | man-recode | manpath | update-mime-database) continue ;;
    esac
    if [ ! -e "$WRAP_DIR/$name" ]; then
      ln -s nix "$WRAP_DIR/$name"
      printf "  wrapped: %s\n" "$name"
    fi
  done
' 2>/dev/null | grep -v "WARNING: linker" || true

log "Done. Installed tools are now on PATH via ~/.local/bin"