#!/usr/bin/env bash
set -euo pipefail

# nix-install.sh — ONE-COMMAND bootstrap for a fresh Termux phone.
#
# Turns a stock Termux app into a fully managed device of the dotfiles flake:
#   - Nix (2.35.1) running natively inside a kernel chroot (the phone's "/" is
#     dm-verity read-only, so a real /nix mountpoint is impossible; the store
#     lives at ~/.nix/nix and is bind-mounted at /nix inside the chroot).
#     Requires root (KernelSU/Magisk) for the bind mounts + chroot.
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
# Stable alias for the Termux user inside the chroot: the fake /etc/passwd maps
# this name to each device's real uid/gid, so it works on any phone.
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
# nix-chroot needs root (KernelSU/Magisk) for the bind mounts + chroot.
if ! have su; then
  warn "no su found — nix-chroot needs root (KernelSU/Magisk). Aborting."
  exit 1
fi
su -c 'id -u' 2>/dev/null | grep -q '^0$' \
  || warn "su is present but not granting root — nix-chroot will fail."

log "Installing Termux prerequisites (git, fish, openssh, termux-api)"
printf 'N\n' | pkg update -y
pkg_install git fish openssh termux-api

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
log "Setting up fake /etc and the chroot rootfs"
USER_UID="$(id -u)"
USER_GID="$(id -g)"

mkdir -p "$NIX_ROOT"/{nix,etc/nix,tmp,bin,src,shm}
# Bind-mount targets inside the chroot rootfs (filled in by nix-chroot-run).
mkdir -p "$ROOTFS"/{nix,etc,tmp,src,dev/shm,proc,dev,sys,system,apex,vendor,product,system_ext}
mkdir -p "$ROOTFS/data/data/com.termux"
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

# --------------------------------------------------------------- nix-chroot
# Kernel chroot helper (replaces proot): bind-mounts the store at /nix inside
# a rootfs on /data and chroots in. Needs root (KernelSU/Magisk) + busybox
# (mount/unshare/chroot/setuidgid), copied into the Termux prefix so it is
# available inside the chroot too.
log "Copying busybox for use inside the chroot ($PREFIX/bin/busybox)"
BUSYBOX_SRC="$(su -c 'command -v busybox' 2>/dev/null || true)"
if [ -n "$BUSYBOX_SRC" ] && [ "$BUSYBOX_SRC" != "$PREFIX/bin/busybox" ]; then
  cp -f "$BUSYBOX_SRC" "$PREFIX/bin/busybox"
  chmod 755 "$PREFIX/bin/busybox"
elif [ ! -x "$PREFIX/bin/busybox" ]; then
  warn "no busybox found via su — nix-chroot needs it (install KernelSU/Magisk busybox)"
  exit 1
fi

log "Writing the chroot helpers ($NIX_BIN_DIR/nix-chroot{,-run})"
mkdir -p "$NIX_BIN_DIR"
cat > "$NIX_BIN_DIR/nix-chroot" <<'SCRIPT'
#!/data/data/com.termux/files/usr/bin/sh
# nix-chroot: run a command natively inside a chroot, using KernelSU root.
#
# Replaces nix-proot. Same wrapper contract (argv[1..] is the command to run
# inside the Nix environment), but instead of ptrace-based proot it uses a real
# kernel chroot + bind mounts. The store (/nix) and a fake /etc live on
# writable /data; the phone's real "/" is dm-verity read-only, so a real /nix
# mountpoint is impossible — hence chroot. Everything runs with the real kernel
# and real glibc (no syscall interception), so Nix is effectively native.
set -eu

B="/data/data/com.termux/files/usr/bin/busybox"

# Elevate to root. KernelSU `su 0 CMD ARGS...` execs CMD directly (no shell
# re-parsing), so "$@" passes through verbatim.
if [ "$(id -u 2>/dev/null || echo 1)" != "0" ]; then
  exec su 0 /data/data/com.termux/files/usr/bin/sh "$0" "$@"
fi

# --- root context ---
unset LD_PRELOAD LD_LIBRARY_PATH
export USER="u0_a393"
export HOME="/data/data/com.termux/files/home"
export NIX_SSL_CERT_FILE="/data/data/com.termux/files/usr/etc/tls/cert.pem"
export PATH="$HOME/.nix-profile/bin:$PATH"
export NIX_ROOT="${NIX_ROOT:-$HOME/.nix}"
export ROOTFS="$NIX_ROOT/rootfs"
export STORE="$NIX_ROOT/nix"
export ETC="$NIX_ROOT/etc"
export TMP="$NIX_ROOT/tmp"
export SRC="$NIX_ROOT/src"
export SHM="$NIX_ROOT/shm"
export NIX_CWD="$(pwd)"

# Run in a private mount namespace: KernelSU's su shares a persistent mount
# namespace, so without this every invocation would stack another full set of
# bind mounts (they'd only vanish on reboot).
exec "$B" unshare -m --propagation private \
  /data/data/com.termux/files/usr/bin/sh "$HOME/.nix/bin/nix-chroot-run" "$@"
SCRIPT
chmod +x "$NIX_BIN_DIR/nix-chroot"

cat > "$NIX_BIN_DIR/nix-chroot-run" <<'SCRIPT'
#!/data/data/com.termux/files/usr/bin/sh
# nix-chroot-run: (runs as root, in a private mount ns) bind-mount the Nix
# store + fake /etc into the rootfs, chroot into it, drop to the Termux user
# (u0_a393) and exec the requested command. Config comes from env (set by
# nix-chroot); "$@" is the command + its arguments.
set -eu
B="/data/data/com.termux/files/usr/bin/busybox"

mkdir -p \
  "$ROOTFS/nix" "$ROOTFS/etc" "$ROOTFS/tmp" "$ROOTFS/src" \
  "$ROOTFS/dev/shm" "$ROOTFS/proc" "$ROOTFS/dev" "$ROOTFS/sys" \
  "$ROOTFS/system" "$ROOTFS/apex" "$ROOTFS/vendor" "$ROOTFS/product" \
  "$ROOTFS/system_ext" "$ROOTFS/data/data/com.termux"

# --bind for plain directories on /data (no submounts); --rbind for the
# Android partitions that are themselves mounts with submounts (e.g. /apex
# is a tmpfs whose per-package dirs are loop mounts, and the bionic linker
# lives at /apex/com.android.runtime/bin/linker64).
"$B" mount -o bind  "$STORE" "$ROOTFS/nix"
"$B" mount -o bind  "$ETC"   "$ROOTFS/etc"
"$B" mount -o bind  "$TMP"   "$ROOTFS/tmp"
"$B" mount -o bind  "$SRC"   "$ROOTFS/src"
"$B" mount -o bind  "$SHM"   "$ROOTFS/dev/shm"
"$B" mount -o rbind /proc        "$ROOTFS/proc"
"$B" mount -o rbind /dev         "$ROOTFS/dev"
"$B" mount -o rbind /sys         "$ROOTFS/sys"
"$B" mount -o rbind /system      "$ROOTFS/system"
"$B" mount -o rbind /apex        "$ROOTFS/apex"
"$B" mount -o rbind /vendor      "$ROOTFS/vendor"
"$B" mount -o rbind /product     "$ROOTFS/product"
"$B" mount -o rbind /system_ext  "$ROOTFS/system_ext"
"$B" mount -o rbind /data/data/com.termux "$ROOTFS/data/data/com.termux"

# busybox chroot chdir(2)s to "/" after chrooting, which would break relative
# flake refs (e.g. `home-manager switch --flake .#...`). Restore the caller's
# cwd first (it is reachable inside the chroot as long as it lives under
# /data/data/com.termux, which is bind-mounted). setuidgid drops to u0_a393
# (from the fake /etc/passwd) so store/home files stay owned by the Termux
# user, not root.
exec "$B" chroot "$ROOTFS" /bin/sh -c '
  cd "${NIX_CWD:-/}" 2>/dev/null || cd /
  exec /bin/busybox setuidgid u0_a393 "$@"
' sh "$@"
SCRIPT
chmod +x "$NIX_BIN_DIR/nix-chroot-run"

# ------------------------------------------------------------------- tarball
# ~/.nix-profile is a symlink into /nix, which is only visible inside the
# chroot — so probe it with nix-chroot, not from the Termux side.
if "$NIX_BIN_DIR/nix-chroot" /bin/sh -c '[ -x "$HOME/.nix-profile/bin/nix" ]' 2>/dev/null; then
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

  # Single-user install: no daemon, no channel, no profile edits. The store is
  # written at /nix inside the chroot, owned by the Termux user.
  log "Installing Nix inside the chroot (single-user)"
  "$NIX_BIN_DIR/nix-chroot" /bin/sh \
    "$NIX_ROOT/src/unpack/nix-$NIX_VERSION-aarch64-linux/install" \
    --no-daemon --no-channel-add --no-modify-profile
fi

# ------------------------------------------------------------------- wrappers
log "Installing PATH wrappers (~/.local/bin)"
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/nix" <<'WRAP'
#!/data/data/com.termux/files/usr/bin/sh
# nix wrapper for the chroot-in-Termux Nix installation.
# Each symlink name (nix, nix-env, nix-shell, home-manager, bat, ...) maps to
# the matching binary in the Nix profile (~/.nix-profile/bin) executed inside
# a kernel chroot (via KernelSU root), so everything works from a plain
# Termux shell.
cmd="$(basename "$0")"

exec "$HOME/.nix/bin/nix-chroot" "$HOME/.nix-profile/bin/$cmd" "$@"
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
# Nix (chroot-in-Termux) entry points
fish_add_path -m ~/.local/bin
FISH
for rc in "$HOME/.bashrc" "$HOME/.profile"; do
  if [ ! -f "$rc" ] || ! grep -q "nix-termux" "$rc" 2>/dev/null; then
    cat >> "$rc" <<'RC'
# Nix (chroot-in-Termux) entry points
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