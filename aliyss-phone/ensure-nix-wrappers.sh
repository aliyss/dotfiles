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
# List the profile's bins from inside the chroot (read-only)…
tools="$("$NIX_CHROOT" /bin/sh -c '
  for tool in "$HOME/.nix-profile/bin"/*; do
    [ -e "$tool" ] || continue
    name=$(basename "$tool")
    case "$name" in
      # nix* / home-manager already have explicit wrappers in ~/.local/bin
      nix | home-manager | nix-*) continue ;;
      # man-db internals are a home-manager dependency, not user packages
      man | mandb | apropos | whatis | accessdb | catman | lexgrog | man-recode | manpath | update-mime-database) continue ;;
    esac
    printf "%s\n" "$name"
  done
' 2>/dev/null | grep -v "WARNING: linker" || true)"

# …but create the symlinks from the Termux side. Links made through su/chroot
# lose the app's SELinux MLS categories (u:object_r:app_data_file:s0 instead of
# s0:c137,c257,c512,c768) and become unreadable by the Termux app. `ln -sfn`
# also repairs any such broken links from previous runs.
for name in $tools; do
  # [ -e ] is false for both missing links and SELinux-blocked ones.
  if [ ! -e "$WRAP_DIR/$name" ]; then
    # A SELinux-blocked stale link cannot be replaced as the app user (the
    # MLS check denies unlink too) — remove it as root once:
    #   su -c 'rm -f ~/.local/bin/tailscale'
    ln -sfn nix "$WRAP_DIR/$name" 2>/dev/null || true
    if [ -e "$WRAP_DIR/$name" ]; then
      printf "  wrapped: %s\n" "$name"
    else
      printf "  !! could not wrap %s (SELinux?) — see script comment\n" "$name" >&2
    fi
  fi
done

log "Done. Installed tools are now on PATH via ~/.local/bin"