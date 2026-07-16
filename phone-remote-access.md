# Phone Remote Access — herdr & Terminals

Take your desktop terminals and your herdr workspace with you on the phone.
herdr is itself a multiplexer — every client (every foot pane, every SSH
session, every phone) attaches to the same per-user daemon over a Unix
socket. So from the phone, you just `ssh` into the desktop and run herdr,
and you see exactly what the desktop sees.

> From the herdr docs: *"Work from your phone: you do not need a Herdr
> mobile app or a web dashboard. Install any SSH client on your phone,
> connect to the machine where your agents run, and start Herdr there…
> The same persistent Herdr session opens in your phone terminal. The TUI
> adapts to narrow screens, so you can inspect agents, switch workspaces,
> and check panes without leaving SSH."*
> — https://herdr.dev/docs/how-to-work/

## How it works

```text
┌─ desktop (bequitta) ───────────────┐      ┌─ phone (Termux) ──────────┐
│ foot ─► fish ─► herdr-workspace ──►│      │ ssh -p 22922 ─► fish ─►  │
│              ▲                     │      │              herdr-workspace│
│              └─ shared daemon ─────┼──────┼──────────────► herdr ──────┤
└────────────────────────────────────┘      └────────────────────────────────┘
                  herdr daemon (per-user, on a Unix socket)
                  log: ~/.config/herdr/herdr.log
```

- A single **herdr daemon** runs per user (started by `herdr server`).
  Servers of the same user share one daemon; multiple `herdr` clients
  attach to it. Herdr is the analogue of tmux but with a richer TUI
  (workspaces, agents, panes, tabs, command palette, sessionizer,
  file viewer, etc.).
- Every interactive fish shell — every pane on the desktop, every fresh
  SSH session from the phone — calls `herdr-workspace "main"`. That
  helper (defined in `flake/home-manager/apps/herdr.nix`):
  1. starts the daemon if it isn't running (`herdr server &`),
  2. waits up to ~6 s for it to be ready,
  3. focuses the workspace labelled `main` (creating it on first run),
  4. `exec`s the herdr client so the terminal becomes a herdr TUI
     connected to that daemon.
- That makes desktop panes and phone SSH sessions all share the same
  daemon state. No tmux required.
- `openssh` listens on TCP **22922** (already in the firewall), so the
  phone's SSH client reaches the desktop and lands in fish.

## herdr's own remote option (FYI, not the default phone path)

herdr 0.7.1 also ships `herdr --remote <ssh-target>` which lets a
*local* terminal stream a remote herdr session over SSH
(e.g. `herdr --remote ssh://aliyss@bequitta:22922`). The advantages
are local clipboard-image bridging and local keybinding profiles. The
drawbacks are: it requires herdr to be installed on the phone too, and
it bypasses the native per-user daemon model. **Plain `ssh` + `herdr`
is the docs-recommended phone path** and the one we set up here. You
can switch later by installing herdr on the phone
(`curl -fsSL https://herdr.dev/install.sh | sh`) and dropping the line
`exec herdr-workspace "main"` from `flake/home-manager/apps/fish.nix`
in favour of detached `-Remote` invocations.

## What you already need on the phone

You said you already have **Termux**. That's all.

Optional:

- **Termius** / **JuiceSSH** — friendlier than bare `ssh` (key
  management, snippets, port-forward UI).
- **Hacker's Keyboard** (F-Droid / Play Store) — on-screen keyboards
  lay out `Ctrl`/`Alt` awkwardly. Hacker's Keyboard has them as a
  modifier layer, which makes herdr's hotkeys much easier.

## One-time setup on the phone

In Termux:

```bash
# 1. Bring Termux up to date.
pkg update && pkg upgrade -y

# 2. Install openssh client.
pkg install openssh

# 3. (Recommended) Install `mosh` for resilient roaming.
pkg install mosh
```

## Connecting while on the same Wi-Fi as the desktop

```bash
ssh -p 22922 aliyss@<desktop-lan-ip>
```

You'll land in fish which immediately `exec`s `herdr-workspace "main"`,
attaching the phone as a herdr client on your desktop's daemon.

## Connecting from outside the home network

Two clean options:

1. **Port-forward 22922 on your home router** to the desktop's LAN IP.
   Then over the internet:
   ```bash
   ssh -p 22922 aliyss@<your-public-ip-or-ddns>
   ```

2. **Use a tunnel** — your flake already has `playit-nixos-module` as
   a flake input (see `flake/flake.nix`). Once the claim secret is
   wired in, expose TCP 22922 from `playit.gg`, then:
   ```bash
   ssh -p <playit-port> aliyss@<playit-host>
   ```

For CGNAT (most mobile carriers), option (2) is the only practical
one.

Use `mosh` instead of raw SSH on flaky mobile data — it stays coherent
across Wi-Fi ↔ LTE handoff without dropping herdr:

```bash
mosh --ssh="ssh -p 22922" aliyss@<desktop-ip>
```

Both ends need mosh:

- on the **phone**: `pkg install mosh` (Termux);
- on the **desktop**: `services.mosh.enable = true` is already set in
  `flake/modules/services/misc.nix`, which makes `mosh-server` listen and
  auto-opens UDP 60000–61000 in the firewall.

## Using herdr from the phone

Once you're in, the phone mirrors the desktop herdr UI. Termux hotkey
tips:

| Action                                | Keys                                          |
|---------------------------------------|-----------------------------------------------|
| herdr prefix                          | `Ctrl+Space` — on Termux: `VolumeUp` then `Space` |
| Pane nav (`ctrl+h/j/k/l`)             | `VolumeUp` then `H` / `J` / `K` / `L`         |
| Selection (mouse drag)                | tap-and-hold, drag                            |
| Quit herdr (back to fish prompt)      | `Ctrl+Space` then `q`                         |
| Disconnect phone SSH                  | `Ctrl+D` (or just close Termux)               |

You don't need to disconnect deliberately when leaving — the herdr
daemon keeps your workspace open. Next time you SSH in, you resume
where you were.

## `~/.ssh/config` on the phone

```sshconfig
Host bequitta
    HostName <DESKTOP-LAN-IP>    # run `hostname -I | awk '{print $1}'` on desktop
    Port 22922
    User aliyss
    RequestTTY yes              # required: gives fish + herdr a real PTY
    # No RemoteCommand — fish's interactiveShellInit execs
    # `herdr-workspace "main"` itself.
```

Then:

```bash
ssh bequitta        # same as `ssh -p 22922 aliyss@<desktop-lan-ip>`
```

## Security checklist

This opens a port. Be deliberate:

- [ ] **Keys-only auth** (recommended).
  1. On the phone:
     ```bash
     ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519
     cat ~/.ssh/id_ed25519.pub
     ```
  2. On the desktop, append that public key to `~/.ssh/authorized_keys`,
     and `chmod 600` it.
  3. Smoke-test from the phone (still with password auth on):
     `ssh -p 22922 aliyss@bequitta` should log in without a password.
  4. Then in `flake/modules/services/misc.nix`, flip
     `PasswordAuthentication = false;` and run
     `sudo update-system -s bequitta`.

- [ ] Restrict by source IP if 22922 is publicly forwarded.
- [ ] `AllowUsers = ["aliyss"]` is already set in
      `flake/modules/services/misc.nix`.
- [ ] Consider port-knocking if you don't want the port always
      discoverable.

## What survives what

| Event                                    | Result                                  |
|------------------------------------------|------------------------------------------|
| Phone disconnects                        | Desktop herdr keeps running; daemon stays up; pane state preserved. Reconnect = resume where you were. |
| Desktop suspends / phone Wi-Fi drops     | Same — daemon stays up on desktop. (Use `mosh` to survive network handoff.) |
| Phone goes offline for days              | Same — daemon is still there, workspaces/panes are still there. |
| Herdr daemon crashes (rare)              | Next `herdr` invocation auto-starts a fresh daemon. `herdr-workspace "main"` recreates the `main` workspace for you. |
| Desktop reboots                          | **Herdr has no built-in resurrect/continuum equivalent. Pane layouts and running processes are gone. The next SSH session starts a fresh daemon.** (The new session still picks up `~/.local/share/herdr/*` if herdr persists anything there, but in 0.7.1 there's no save-on-exit.) |

## Files changed for this setup

All under the flake in this directory:

- `flake/home-manager/apps/herdr.nix`         — defines the `herdr-workspace` helper that this flow depends on.
- `flake/home-manager/apps/fish.nix`          — interactive shell `exec`s `herdr-workspace "main"` on every interactive start.
- `flake/modules/services/misc.nix`           — enables `openssh` on TCP **22922**, hardened.
- `flake/modules/core/networking.nix`         — unchanged (port 22922 was already in `allowedTCPPorts`).

Apply in this order:

```bash
update-home                                # fish + herdr-workspace hookup
sudo update-system -s bequitta            # openssh + firewall
```

## Verify from the desktop

Once `sudo update-system -s bequitta` has run:

```bash
ssh -p 22922 -o StrictHostKeyChecking=accept-new aliyss@localhost \
    'echo ok; command herdr status server; command herdr workspace list'
```

If you see `ok` and `herdr workspace list` shows your `main` workspace,
the round-trip works.

## A. Find your desktop's IP

```bash
hostname -I | awk '{print $1}' # e.g. 192.168.1.26
```
