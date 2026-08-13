# Phone Management (aliyss-phone)

This folder contains documentation and scripts for managing the Android (Termux)
phone as a **managed device of the dotfiles flake** — same central theme
(`flake/lib/theme.nix`) as the desktop, applied declaratively via home-manager
(which runs inside the existing Termux app through `proot`).

## How it works

- The phone is registered in `flake/flake.nix` as
  `homeConfigurations.aliyss-termux` (`flake/hosts/termux/home.nix`, aarch64).
- That config shares the same theme and app modules as the desktop
  (`flake/home-manager/themes/default.nix`, `apps/fish.nix`, `apps/herdr.nix`),
  with `aliyss.isPhone = true` gating the phone-specific bits: real-file
  configs written directly on the phone (`~/.termux/colors.properties`,
  `~/.config/fish/config.fish`, `~/.hushlogin`), Tailscale/sshd handling,
  and no Hyprland.
- Nix itself runs inside the Termux app via `proot` (the phone's `/` is
  dm-verity read-only, so a native `/nix` mount is impossible). The store lives
  at `~/.nix/nix`; no app, no mount, no root needed.
- Every tool installed via `home.packages` is automatically wrapped into
  `~/.local/bin` (`ensure-nix-wrappers.sh`, run by `update-home.sh` after each
  switch), so `bat`, `eza`, `fd`, `jq`, `rg`, `btop`, `nix` and `home-manager`
  all work from a normal Termux shell (fish or bash) — the wrapper transparently
  runs the glibc binary inside proot.

## Fresh phone (bootstrap)

On a fresh Termux, **one command** sets everything up:

```bash
curl -fsSL https://raw.githubusercontent.com/aliyss/dotfiles/master/aliyss-phone/nix-install.sh | bash
```

`nix-install.sh` does all of it:

- installs prerequisites (`proot`, `git`, `fish`, `openssh`, `termux-api`),
- sets fish as the default shell (`~/.termux/shell`),
- starts `sshd` and (optionally) writes `~/.ssh/authorized_keys` from
  `SSH_AUTHORIZED_KEYS`,
- installs the patched Tailscale and starts its daemon,
- builds the proot-faked Nix environment (`/nix` → `~/.nix/nix`), installs Nix
  (single-user) + home-manager,
- installs PATH wrappers so `nix`, `home-manager` and every `home.packages`
  tool work from a plain Termux shell (fish or bash),
- clones/merges this repo into `~/.config` (the dotfiles convention — the repo
  IS `~/.config`, flake at `~/.config/flake`) and applies the phone config
  (theme, tools, aliases, opencode theme, `.hushlogin`).

The only manual step after the command: authorize the phone on your tailnet —
`tailscale-cli up` (opens/prints an auth URL; one-time).

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
```

Or, to only re-apply without pulling: `PULL=0 ~/.config/aliyss-phone/update-home.sh`.
The scripts live in `aliyss-phone/` (`update-home.sh`, `update-system.sh`,
`ensure-nix-wrappers.sh`); `update-phone.sh` is kept as a compat wrapper for
`update-home.sh`.

> The Nix binary itself is version-pinned by `nix-install.sh` (`NIX_VERSION`);
> bump it there to update Nix (`nix upgrade-nix` is unavailable because the
> profile is managed by `nix profile`).

## Manual setup — now handled by nix-install.sh

The steps that used to be manual are automated: Tailscale (patched, daemon on),
`pkg install openssh fish termux-api`, fish as default shell, sshd. The only
remaining manual bits:
- `tailscale-cli up` (one-time device authorization on your tailnet), and
- optionally pass `SSH_AUTHORIZED_KEYS='ssh-ed25519 AAAA...'` to
  `nix-install.sh` to add your desktop's key (default: no key is added).

## SSH Shortcuts

The phone is accessible via Tailscale at:

- **Hostname**: `aliyss-termux` (or use the IP directly)
- **Port**: `8022`
- **User**: `aliyss`

## Tailscale Commands (Patched version)

- `tailscaled-start`: Starts the daemon or manages the service (`--service=on/off/status`).
- `tailscale-cli`: The command to use instead of raw `tailscale` (it uses the correct socket).
- `tailscaled-log`: View the daemon logs.
- `tailscale-test`: Verify the connection.

## Generated files

Everything the old `sync-phone.sh` pushed over scp is now written by
home-manager on the phone:

- `~/.termux/colors.properties` — Termux colors
- `~/.config/fish/config.fish` — fish config
- `~/.hushlogin` — suppress the Termux login banner
- plus `home.packages` (bat, btop, eza, fd, jq, ripgrep)

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
