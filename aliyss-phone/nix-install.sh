#!/usr/bin/env bash
set -euo pipefail

# nix-install.sh — ONE-COMMAND bootstrap for a fresh Termux phone.
#
# Turns a stock Termux app into a fully managed device of the dotfiles flake:
#   - Nix (2.35.1) running inside proot (the phone's "/" is dm-verity read-only,
#     so a native /nix mount is impossible; the store lives at ~/.nix/nix).
#   - home-manager config applied: theme (Termux colors + fish + opencode),
#     tools (bat, btop, eza, fd, jq, rg), aliases (update-home/system/flake),
#     .hushlogin, packages — all written as REAL files readable by native apps.
#   - wrappers so every installed tool works from a plain Termux shell.
#   - fish as the default shell, sshd running, patched Tailscale installed.
#
# Prerequisite: the dotfiles repo (with flake/hosts/termux, the aliyss-phone
# scripts and the theme changes) must be pushed to REPO_URL before running.
#
# Usage:   bash nix-install.sh
# Options (env vars):
#   NIX_VERSION            nix release to install        (default 2.35.1)
#   REPO_URL               dotfiles repo to clone        (default https://github.com/aliyss/dotfiles)
#   REPO_DIR               where to merge it             (default ~/.config — the dotfiles convention)
#   RUN_UPDATE             apply the home config at end  (default 1)
#   INSTALL_TAILSCALE      install patched Tailscale     (default 1; auth is manual)
#   SSH_AUTHORIZED_KEYS    desktop public key(s) to put in ~/.ssh/authorized_keys
#
# Idempotent: safe to re-run; existing steps are skipped.

NIX_VERSION="${NIX_VERSION:-2.35.1}"
NIX_SHA256="${NIX_SHA256:-79b739996f1751573b4d2b56e4ae607855184c711f2cc1274fa0952a13d4bfc9}"
NIX_ROOT="$HOME/.nix"
NIX_BIN_DIR="$NIX_ROOT/bin"
ROOTFS="$NIX_ROOT/rootfs"
TARBALL="$NIX_ROOT/src/nix-$NIX_VERSION-aarch64-linux.tar.xz"
REPO_URL="${REPO_URL:-https://github.com/aliyss/dotfiles}"
REPO_DIR="${REPO_DIR:-$HOME/.config}"
RUN_UPDATE="${RUN_UPDATE:-1}"
INSTALL_TAILSCALE="${INSTALL_TAILSCALE:-1}"
# Stable alias for the Termux user inside proot: the fake /etc/passwd maps this
# name to each device's real uid/gid, so it works on any phone.
T_USER="u0_a393"
T_HOME="/data/data/com.termux/files/home"

log() { printf '\n\033[1;34m== %s ==\033[0m\n' "$*"; }
warn() { printf '\033[1;33m!! %s\033[0m\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }
# pkg sometimes asks about a modified conffile (e.g. sshd_config) on upgrade;
# answer "N" (keep current) so the script never hangs on a prompt.
pkg_install() { printf 'N\n' | pkg install -y "$@"; }

case "$(uname -m)" in
  aarch64 | arm64) : ;;
  *)
    warn "uname -m is '$(uname -m)'; this script assumes aarch64 (most Android phones)."
    ;;
esac

# ---------------------------------------------------------------- prerequisites
log "Installing Termux prerequisites (proot, git, fish, openssh, termux-api)"
printf 'N\n' | pkg update -y
pkg_install proot git fish openssh termux-api

# Make fish the default Termux shell (Termux honors ~/.termux/shell).
log "Setting fish as the default shell"
if [ "$(readlink "$HOME/.termux/shell" 2>/dev/null || true)" != "$PREFIX/bin/fish" ]; then
  mkdir -p "$HOME/.termux"
  ln -sfn "$PREFIX/bin/fish" "$HOME/.termux/shell"
fi

# Start sshd so the desktop can reach the phone.
log "Starting sshd"
if [ ! -e "$HOME/.ssh" ]; then mkdir -p "$HOME/.ssh"; chmod 700 "$HOME/.ssh"; fi
if [ -n "${SSH_AUTHORIZED_KEYS:-}" ]; then
  printf '%s\n' "$SSH_AUTHORIZED_KEYS" > "$HOME/.ssh/authorized_keys"
  chmod 600 "$HOME/.ssh/authorized_keys"
fi
if ! pgrep -x sshd >/dev/null 2>&1; then
  sshd || warn "sshd failed to start (install openssh and re-run)"
fi

# Patched Tailscale (Android 11+). "tailscale-cli up" needs a one-time login —
# the auth URL is printed for you to open on the desktop.
if [ "$INSTALL_TAILSCALE" = "1" ]; then
  if ! have tailscale-cli; then
    log "Installing patched Tailscale (Android 11+ compatible)"
    curl -fsSL https://raw.githubusercontent.com/bropines/tailscale-termux-cli/main/remote-install.sh | bash \
      || warn "Tailscale install failed (skip with INSTALL_TAILSCALE=0)"
  fi
  if have tailscaled-start; then
    tailscaled-start --service=on 2>/dev/null || true
  fi
  if have tailscale-cli && tailscale-cli status >/dev/null 2>&1; then
    log "Tailscale is already up"
  else
    warn "Tailscale daemon started. Authorize this phone once:  tailscale-cli up"
  fi
fi

# ------------------------------------------------------- fake /etc + fake root
log "Setting up fake /etc and a readable fake /"
USER_UID="$(id -u)"
USER_GID="$(id -g)"

mkdir -p "$NIX_ROOT"/{nix,etc/nix,tmp,bin,src,shm}
mkdir -p "$ROOTFS/data/data"
chmod 1777 "$NIX_ROOT/shm"

cat > "$NIX_ROOT/etc/resolv.conf" <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF
cat > "$NIX_ROOT/etc/hosts" <<'EOF'
127.0.0.1 localhost
::1       localhost
EOF
cat > "$NIX_ROOT/etc/passwd" <<EOF
root:x:0:0:root:/root:/bin/sh
$T_USER:x:$USER_UID:$USER_GID::$T_HOME:/bin/sh
EOF
cat > "$NIX_ROOT/etc/group" <<EOF
root:x:0:
$T_USER:x:$USER_GID:
nixbld:x:30000:
EOF
cat > "$NIX_ROOT/etc/nix/nix.conf" <<'EOF'
sandbox = false
experimental-features = nix-command flakes
EOF

ln -sfn "$PREFIX/bin" "$ROOTFS/bin"
ln -sfn "$PREFIX" "$ROOTFS/usr"

# ------------------------------------------------------------------ nix-proot
log "Writing the proot helper ($NIX_BIN_DIR/nix-proot)"
mkdir -p "$NIX_BIN_DIR"
cat > "$NIX_BIN_DIR/nix-proot" <<SCRIPT
#!/data/data/com.termux/files/usr/bin/sh
# nix-proot: run a command inside the proot-faked Nix environment.
# Fakes /nix -> ~/.nix/nix, /etc -> ~/.nix/etc and overlays a readable fake
# "/" (rootfs) because this device denies readdir on the real "/" for apps
# (nix opens "/" during store init). No root required.
set -eu

unset LD_PRELOAD LD_LIBRARY_PATH
# Deterministic proot env: "$T_USER" is a stable alias for the Termux user
# (fake /etc/passwd maps it to the real uid). home-manager's activation sanity
# checks compare \$USER/\$HOME against the config, so keep them fixed.
export USER="$T_USER"
export HOME="$T_HOME"
export NIX_SSL_CERT_FILE="${NIX_SSL_CERT_FILE:-\$PREFIX/etc/tls/cert.pem}"
# Inside proot prefer the real nix binaries so tools like the home-manager
# activation script (which locates nix via \`type -p nix-env\`) run the store
# binaries instead of re-entering this wrapper.
export PATH="\$HOME/.nix-profile/bin:\$PATH"

ROOTFS="\$HOME/.nix/rootfs"
mkdir -p "\$ROOTFS"
mkdir -p "\$ROOTFS/data/data"

PROOT_BIN="\${PROOT_BIN:-\$PREFIX/bin/proot}"
[ -x "\$PROOT_BIN" ] || PROOT_BIN="\$(command -v proot || true)"
[ -n "\$PROOT_BIN" ] || { echo "nix-proot: proot not found" >&2; exit 1; }

exec "\$PROOT_BIN" \\
  --sysvipc \\
  -b "\$ROOTFS:/" \\
  -b "\$HOME/.nix/nix:/nix" \\
  -b "\$HOME/.nix/etc:/etc" \\
  -b "\$HOME/.nix/tmp:/tmp" \\
  -b "\$HOME/.nix/src:/src" \\
  -b "\$ROOTFS/data:/data" \\
  -b "\$ROOTFS/data/data:/data/data" \\
  -b /data/data/com.termux:/data/data/com.termux \\
  -b /proc:/proc \\
  -b /dev:/dev \\
  -b "\$HOME/.nix/shm:/dev/shm" \\
  -b /sys:/sys \\
  -b /system:/system \\
  -b /apex:/apex \\
  -b /vendor:/vendor \\
  -b /product:/product \\
  -b /system_ext:/system_ext \\
  "\$@"
SCRIPT
chmod +x "$NIX_BIN_DIR/nix-proot"

# ------------------------------------------------------------------- tarball
# ~/.nix-profile is a symlink into /nix, which is only visible inside proot —
# so probe it with nix-proot, not from the Termux side.
if "$NIX_BIN_DIR/nix-proot" /bin/sh -c '[ -x "$HOME/.nix-profile/bin/nix" ]' 2>/dev/null; then
  log "Nix already installed — skipping download + install"
else
  log "Downloading Nix $NIX_VERSION"
  mkdir -p "$NIX_ROOT/src"
  if [ ! -f "$TARBALL" ]; then
    curl -fL -o "$TARBALL" \
      "https://releases.nixos.org/nix/nix-$NIX_VERSION/nix-$NIX_VERSION-aarch64-linux.tar.xz"
  fi
  log "Verifying tarball checksum"
  echo "$NIX_SHA256  $TARBALL" | sha256sum -c - || {
    warn "checksum mismatch — delete $TARBALL and re-run"
    exit 1
  }

  log "Unpacking"
  rm -rf "$NIX_ROOT/src/unpack"
  mkdir -p "$NIX_ROOT/src/unpack"
  tar -xf "$TARBALL" -C "$NIX_ROOT/src/unpack"

  # Single-user install: no root, no daemon, no channel, no profile edits.
  # Requires the fake readable "/" (nix opens it during store init).
  log "Installing Nix inside proot (single-user)"
  "$NIX_BIN_DIR/nix-proot" /bin/sh \
    "$NIX_ROOT/src/unpack/nix-$NIX_VERSION-aarch64-linux/install" \
    --no-daemon --no-channel-add --no-modify-profile
fi

# ------------------------------------------------------------------- wrappers
log "Installing PATH wrappers (~/.local/bin)"
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/nix" <<'WRAP'
#!/data/data/com.termux/files/usr/bin/sh
# nix wrapper for the proot-in-Termux Nix installation.
# Each symlink name (nix, nix-env, nix-shell, home-manager, bat, ...) maps to
# the matching binary in the Nix profile (~/.nix-profile/bin) executed inside
# proot, so everything works from a plain Termux shell.
cmd="$(basename "$0")"

exec "$HOME/.nix/bin/nix-proot" "$HOME/.nix-profile/bin/$cmd" "$@"
WRAP
chmod +x "$HOME/.local/bin/nix"
# Symlink the other nix commands to the wrapper (NOT `nix` itself — it is the
# wrapper script; linking it to itself would dangle).
for cmd in nix-env nix-shell nix-build nix-store nix-channel nix-instantiate \
  nix-collect-garbage nix-prefetch-url nix-copy-closure nix-daemon nix-hash; do
  ln -sfn nix "$HOME/.local/bin/$cmd"
done
ln -sfn nix "$HOME/.local/bin/home-manager"

# PATH hooks so the wrappers are available in every Termux shell.
mkdir -p "$HOME/.config/fish/conf.d"
cat > "$HOME/.config/fish/conf.d/nix-termux.fish" <<'FISH'
# Nix (proot-in-Termux) entry points
fish_add_path -m ~/.local/bin
FISH
for rc in "$HOME/.bashrc" "$HOME/.profile"; do
  if [ ! -f "$rc" ] || ! grep -q "nix-termux" "$rc" 2>/dev/null; then
    cat >> "$rc" <<'RC'
# Nix (proot-in-Termux) entry points
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
RC
  fi
done

# Pre-create nix cache dirs (avoids a libgit2 ENOENT on first fetch).
mkdir -p "$HOME/.cache/nix"/{tarball-cache-v2,git,fetcher-cache-v1,registries,eval-cache-v5}

export PATH="$HOME/.local/bin:$PATH"
log "Verifying nix"
nix --version

# ------------------------------------------------------------------ repo update
# The dotfiles repo IS ~/.config (desktop convention). Since ~/.config already
# exists on the phone (app + home-manager dirs), clone into a temp dir and merge
# the tracked files in, exactly like the desktop setup instructions (README).
if [ "$RUN_UPDATE" = "1" ]; then
  if [ ! -d "$REPO_DIR/.git" ]; then
    log "Merging dotfiles into $REPO_DIR"
    TMP_CLONE="$NIX_ROOT/src/dotfiles-clone"
    rm -rf "$TMP_CLONE"
    git clone --depth 1 "$REPO_URL" "$TMP_CLONE"
    mkdir -p "$REPO_DIR"
    shopt -s dotglob
    for item in "$TMP_CLONE"/*; do
      name="$(basename "$item")"
      case "$name" in .git | .gitignore) continue ;; esac
      if [ -e "$REPO_DIR/$name" ]; then
        warn "keeping existing $REPO_DIR/$name (merge repo file manually if needed)"
      else
        mv "$item" "$REPO_DIR/"
      fi
    done
    shopt -u dotglob
    mv "$TMP_CLONE/.git" "$REPO_DIR/.git"
    mv "$TMP_CLONE/.gitignore" "$REPO_DIR/.gitignore"
    rm -rf "$TMP_CLONE"
  else
    log "Pulling dotfiles in $REPO_DIR"
    git -C "$REPO_DIR" pull --ff-only || warn "pull failed (will still try to switch)"
  fi
  exec bash "$REPO_DIR/aliyss-phone/update-phone.sh"
fi

log "Done. Nix is installed."
log "Next steps:"
echo "  - apply the config:   $REPO_DIR/aliyss-phone/update-phone.sh"
echo "  - authorize Tailscale: tailscale-cli up"
echo "  - new shell (fish) is the default; reload it and use update-home / update-system"