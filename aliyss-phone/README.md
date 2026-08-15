# Phone Management (aliyss-phone)

This folder contains documentation and scripts for managing the Android (Termux)
phone as a **managed device of the dotfiles flake** — same central theme
(`flake/lib/theme.nix`) as the desktop, applied declaratively via home-manager
(which runs inside the existing Termux app through a kernel `chroot`).

## How it works

- The phone is registered in `flake/flake.nix` as
  `homeConfigurations.aliyss-termux` (`flake/hosts/termux/home.nix`, aarch64).
- That config shares the same theme and app modules as the desktop
  (`flake/home-manager/themes/default.nix`, `apps/fish.nix`, `apps/herdr.nix`),
  with `aliyss.isPhone = true` gating the phone-specific bits: real-file
  configs written directly on the phone (`~/.termux/colors.properties`,
  `~/.config/fish/config.fish`, `~/.hushlogin`), Tailscale/sshd handling,
  and no Hyprland.
- Nix itself runs natively inside a kernel `chroot` (the phone's `/` is
  dm-verity read-only, so a real `/nix` mountpoint is impossible). The store
  lives at `~/.nix/nix` and is bind-mounted at `/nix` inside the chroot; this
  needs root (KernelSU/Magisk) for the bind mounts + chroot.
- Every tool installed via `home.packages` is automatically wrapped into
  `~/.local/bin` (`ensure-nix-wrappers.sh`, run by `update-home.sh` after each
  switch), so `bat`, `eza`, `fd`, `jq`, `rg`, `btop`, `nix` and `home-manager`
  all work from a normal Termux shell (fish or bash) — the wrapper transparently
  runs the glibc binary inside the chroot.

## Fresh phone (bootstrap)

On a fresh Termux, **one command** sets everything up:

```bash
curl -fsSL https://raw.githubusercontent.com/aliyss/dotfiles/master/aliyss-phone/nix-install.sh | bash
```

`nix-install.sh` does all of it:

- installs prerequisites (`git`, `fish`, `openssh`, `termux-api`),
- checks for root (`su`) and copies busybox (needed for the chroot's
  mount/unshare/setuidgid),
- sets fish as the default shell (`~/.termux/shell`),
- starts `sshd` and (optionally) writes `~/.ssh/authorized_keys` from
  `SSH_AUTHORIZED_KEYS`,
- (Tailscale is NOT installed here — the flake builds the patched binaries
  and owns the runit service; see the Tailscale section below),
- builds the chroot Nix environment (bind-mounts `~/.nix/nix` at `/nix` inside
  the rootfs), installs Nix (single-user) + home-manager,
- installs PATH wrappers so `nix`, `home-manager` and every `home.packages`
  tool work from a plain Termux shell (fish or bash),
- clones/merges this repo into `~/.config` (the dotfiles convention — the repo
  IS `~/.config`, flake at `~/.config/flake`) and applies the phone config
  (theme, tools, aliases, opencode theme, `.hushlogin`).

The only manual step after the command: authorize the phone on your tailnet —
`tailscale up` (opens/prints an auth URL; one-time).

> Prerequisite: the repo must already contain `flake/hosts/termux`,
> `flake/home-manager/options.nix`, `flake/home-manager/themes/default.nix`,
> `flake/home-manager/apps/fish.nix` and the `aliyss-phone/` scripts (this
> README) before provisioning a phone.

## Updating the phone

The phone's fish config provides the same commands as the desktop:

```fish
update-system   # Termux base (pkg upgrade) + flake inputs (nix flake update) + home
update-home     # pull repo + rebuild + activate aliyss-termux, reload colors
update-phone    # alias of update-home
upgrade-flake   # nix flake update --flake ~/.config/flake
install-app     # build + pm-install an Android app from aliyss-android-pkgs
```

## Installing Android apps (aliyss-android-pkgs)

The flake inputs [aliyss/aliyss-android-pkgs](https://github.com/aliyss/aliyss-android-pkgs)
and re-exports its package set (`flake/flake.nix`), so every pinned app-id can
be built straight from the dotfiles flake on the phone. `install-app` wraps
the two steps into one: `nix build .#<app-id>` (dotted or dashed id accepted),
then `pm install -r` as root (`su`), resolving the APK from the host-visible
store (`~/.nix/nix/store`, since `/nix` only exists inside the chroot):

```fish
install-app com.darkempire78.opencalculator   # one app
install-app org.videolan.vlc com.spotify.music # several at once
```

The APKs are the pinned, hash-verified artifacts from aliyss-android-pkgs
(F-Droid / IzzyOnDroid / APKPure sources, see that repo's trust model).
`pm install` runs with a 60s poll: if **Google Play Protect** blocks the app
(older/flagged APKs show an "Unsafe app blocked" dialog on the phone), the
script reports it and exits — allow the app in Play Protect on the phone (or
pick another) and re-run. Uninstall as usual:
`su -c 'pm uninstall com.darkempire78.opencalculator'`.

### Declarative installs (`aliyss.androidPkgs`)

Instead of installing ad hoc, apps can be **declared in the home-manager
config** — `flake/hosts/termux/home.nix` (module: `apps/android-pkgs.nix`):

```nix
aliyss.androidPkgs = [
  "com.darkempire78.opencalculator"
  "org.videolan.vlc"
];
```

Every `update-home` (home-manager switch) builds + installs the declared apps
with the same engine as `install-app` (chroot store-path mapping, root
`pm install -r`, bounded 60s Play Protect poll). A blocked/failed app fails
the switch loudly — allow it in Play Protect (or remove the id) and re-run.
Remove an id to stop reinstalling that app (it is not uninstalled).

Or, to only re-apply without pulling: `PULL=0 ~/.config/aliyss-phone/update-home.sh`.
The scripts live in `aliyss-phone/` (`update-home.sh`, `update-system.sh`,
`ensure-nix-wrappers.sh`); `update-phone.sh` is kept as a compat wrapper for
`update-home.sh`.

> The Nix binary itself is version-pinned by `nix-install.sh` (`NIX_VERSION`);
> bump it there to update Nix (`nix upgrade-nix` is unavailable because the
> profile is managed by `nix profile`).

## Manual setup — now handled by nix-install.sh

The steps that used to be manual are automated: `pkg install openssh fish
termux-api`, fish as default shell, sshd. Tailscale is fully declarative now
(flake-owned binaries + service, see below). The only remaining manual bits:
- `tailscale up` (one-time device authorization on your tailnet), and
- optionally pass `SSH_AUTHORIZED_KEYS='ssh-ed25519 AAAA...'` to
  `nix-install.sh` to add your desktop's key (default: no key is added).

## SSH Shortcuts

The phone is accessible via Tailscale at:

- **Hostname**: `aliyss-termux` (or use the IP directly)
- **Port**: `8022`
- **User**: `aliyss`

## Tailscale (declarative, flake-managed)

Tailscale is fully owned by home-manager — the bropines `.deb` / `curl|bash`
installer is gone:

- The patched binaries (`tailscale` + `tailscaled`) are built from source by the
  flake (`flake/packages/tailscale-termux`; upstream bropines patches vendored
  in `flake/packages/tailscale-termux/patches/`) and wrapped into
  `~/.local/bin` like every other nix tool on the phone.
- The runit service (`$PREFIX/var/service/tailscaled/run`) is written by
  `home.activation` and auto-starts at Termux boot via termux-services — the
  same supervision `sshd` gets. A plain `update-home` re-applies it and
  restarts the daemon when the config changes.
- The daemon runs in userspace-networking mode (no `/dev/net/tun`, no root)
  and serves a SOCKS5 proxy on `aliyss.tailscaleSocks5Port` (default `23008`).

Commands:

- `tailscale up` — one-time device authorization on your tailnet (prints an auth URL).
- `tailscale status` / `tailscale ping <host>` — check connectivity.
- `tailscale down` / `tailscale up` — stop/resume the daemon.
- `SVDIR=$PREFIX/var/service sv restart tailscaled` — control the runit
  service directly (plain `sv` can't find the service dir on this phone; the
  daemon runs as a static binary in the app domain, so runit fully controls
  it).

> `tailscale ssh` is not available on the phone: tailscale's built-in SSH does
> not compile for `GOOS=android`, so the daemon is built with `ts_omit_ssh`
> (same limitation as the old `.deb`).

### Troubleshooting

- **Daemon restart drops the phone from the tailnet.** Recovery is on-device:
  `SVDIR=$PREFIX/var/service sv restart tailscaled` (or `pkill -f tailscaled`
  — note pgrep's `-x` flag is broken in this procps build). If that's not
  enough, `su -c 'pkill -9 -f tailscaled'` (a wedged `runsv` may need
  `su -c 'kill -9 <pid>'` — runsvdir respawns it cleanly).
- **Migrating from the old bropines `.deb`:** `dpkg -r tailscale-termux` leaves
  a stale `$PREFIX/var/service/tailscaled/log/` dir whose `run` script is gone;
  runit wedges its runsv on that. The activation removes it automatically, but
  if runsv is wedged from a previous state, delete the dir manually
  (`rm -rf $PREFIX/var/service/tailscaled/log`).

## Generated files

Everything the old `sync-phone.sh` pushed over scp is now written by
home-manager on the phone:

- `~/.termux/colors.properties` — Termux colors
- `~/.config/fish/config.fish` — fish config
- `~/.hushlogin` — suppress the Termux login banner
- `$PREFIX/var/service/tailscaled/run` — the tailscaled runit service (see
  the Tailscale section)
- plus `home.packages` (bat, btop, eza, fd, jq, ripgrep, tailscale-termux,
  zoxide)

These are written as **real files** on the phone (home-manager's `home.file`
links them into the store, but the phone's `/nix` is invisible to native Termux
apps — an activation step copies them out). **Do not edit them directly.**
Modify `flake/lib/theme.nix`, `flake/lib/themes/termux.nix` (colors) or
`flake/home-manager/apps/fish.nix` (fish) — under the `isPhone` branches — then
run `update-home`.

The phone's opencode also gets the generated `catppuccin` theme
(`.config/opencode/themes/catppuccin.json`). The theme is selected via the
tracked `opencode/tui.json` (`"theme": "catppuccin"`), the same as on the
desktop; `opencode.jsonc` stays the tracked repo file.

> `scripts/sync-phone.sh` and the desktop's scp copies are **retired** — the
> phone updates itself from the flake. The repo's `aliyss-phone/scripts/`
> directory can be removed.
