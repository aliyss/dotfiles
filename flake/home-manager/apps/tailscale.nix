{
  pkgs,
  config,
  lib,
  ...
}:
# Phone tailscale, fully managed by home-manager.
#
# There is no systemd on Termux, so home-manager's systemd user services can't
# run here. Termux instead auto-starts everything under $PREFIX/var/service/
# via termux-services (runit) — the same mechanism that supervises sshd. This
# module owns that service declaratively:
#
#   - the tailscale binaries are built by the flake (packages/tailscale-termux)
#     and wrapped into ~/.local/bin by ensure-nix-wrappers.sh for interactive
#     use (they run inside the kernel chroot like every other nix tool);
#   - the DAEMON, however, is copied out of the store by home.activation as a
#     plain file (~/.local/libexec/tailscale-termux/tailscaled): it is a static
#     GOOS=android binary, so it runs natively from Termux with no chroot. That
#     keeps it in the app's SELinux domain (untrusted_app) — if it ran through
#     the chroot's su it would land in the ksu domain, which runit cannot
#     signal (sv restart/down silently fail) and which the app user can't even
#     see in ps or pkill.
#   - the runit service definition (run script + autostart) is written by
#     home.activation, so a plain `update-home` re-applies it and restarts the
#     daemon when the config changes;
#   - the SOCKS5 port is shared with the ssh aliases (fish.nix) via
#     aliyss.tailscaleSocks5Port.
#
# The daemon runs in userspace-networking mode (no /dev/net/tun, no root) and
# serves the SOCKS5 proxy the phone's ssh aliases route through.
let
  isPhone = config.aliyss.isPhone;
  socks5Port = config.aliyss.tailscaleSocks5Port;
  tailscale-termux = pkgs.callPackage ../../packages/tailscale-termux { };
  daemonDir = ".local/libexec/tailscale-termux";

  # Written as a real file into $PREFIX/var/service/tailscaled/run. execs the
  # copied static binary directly (no chroot, no su) so the daemon stays in the
  # app's SELinux domain. --socket is explicit so the CLI (which defaults to
  # ~/.tailscale/tailscaled.sock) and the daemon always agree.
  runScript = ''
    #!/data/data/com.termux/files/usr/bin/sh
    # Managed by home-manager (flake/home-manager/apps/tailscale.nix).
    # tailscaled is a static Nix-built binary copied to ~/.local/libexec by the
    # activation; it runs natively (no chroot) so runit can control it. Do not
    # edit by hand.
    # Logs go to ~/.tailscale/tailscaled.log (there is no runit log service).
    export HOME="/data/data/com.termux/files/home"
    export PATH="$HOME/.local/bin:$PATH"

    {
      echo "=== tailscaled spawned by runit at $(date +%H:%M:%S) ==="
      exec "$HOME/${daemonDir}/tailscaled" \
          --statedir="$HOME/.tailscale" \
          --socket="$HOME/.tailscale/tailscaled.sock" \
          --tun=userspace-networking \
          --socks5-server=127.0.0.1:${socks5Port}
    } >> "$HOME/.tailscale/tailscaled.log" 2>&1
  '';
in {
  home.packages = lib.mkIf isPhone [ tailscale-termux ];

  # The runit service lives outside $HOME ($PREFIX/var/service), so home.file
  # can't write it — install it from activation, same pattern as the phone's
  # real-file configs (copyPhoneFishConfig / copyPhoneAuthorizedKeys).
  home.activation.installTailscaleService = lib.mkIf isPhone (
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      SERVICE_DIR="$PREFIX/var/service/tailscaled"
      mkdir -p "$SERVICE_DIR"

      # One-time migration cleanup: the old bropines deb left a runit log/ dir
      # whose run script dpkg -r removed; runit wedges its runsv on a log dir
      # without a run script. Only touch it when it's actually broken — never
      # remove supervise/ while a runsv is live (that wedges it on this phone).
      if [ -d "$SERVICE_DIR/log" ] && [ ! -x "$SERVICE_DIR/log/run" ]; then
        rm -rf "$SERVICE_DIR/log"
      fi

      # Copy the static daemon out of the store (it is invisible to native
      # Termux as /nix only exists inside the chroot). Refreshed whenever the
      # store path changes (i.e. on tailscale updates).
      mkdir -p "$HOME/${daemonDir}"
      cp -f ${tailscale-termux}/bin/tailscaled "$HOME/${daemonDir}/tailscaled"
      cp -f ${tailscale-termux}/bin/tailscale "$HOME/${daemonDir}/tailscale"
      chmod 755 "$HOME/${daemonDir}/"*

      # Run script is written by Nix (pkgs.writeText) so the shebang and args
      # are exact; /nix/store is visible inside the chroot where activation
      # runs (same as copyPhoneFishConfig).
      cp ${pkgs.writeText "tailscaled-run" runScript} "$SERVICE_DIR/run"
      chmod 755 "$SERVICE_DIR/run"
      # No `down` file => termux-services autostarts the service at Termux boot.
      rm -f "$SERVICE_DIR/down"

      # Apply: restart the daemon so the new run script takes effect. The
      # daemon is in the app domain, so runsv (also app domain) can control it.
      # sv needs SVDIR on this phone (the compiled-in default doesn't resolve);
      # fall back to pkill -f (the daemon's cmdline is visible to the app now;
      # pgrep -x is broken in this procps build). A daemon still lingering in
      # the ksu domain from the old chroot-based script needs a root kill:
      # `su -c 'pkill -9 -f tailscaled'`.
      if [ -d "$SERVICE_DIR/supervise" ]; then
        SVDIR="$PREFIX/var/service" sv restart tailscaled >/dev/null 2>&1 \
          || pkill -f tailscaled >/dev/null 2>&1 || true
        sleep 2
      fi
      SVDIR="$PREFIX/var/service" sv up tailscaled >/dev/null 2>&1 || true

      # Fallback: if the daemon still isn't listening, start it directly so the
      # phone comes up reachable even if runit's sv is unhappy (seen once).
      if ! "$HOME/${daemonDir}/tailscale" status >/dev/null 2>&1; then
        nohup "$HOME/${daemonDir}/tailscaled" \
          --statedir="$HOME/.tailscale" \
          --socket="$HOME/.tailscale/tailscaled.sock" \
          --tun=userspace-networking \
          --socks5-server=127.0.0.1:${socks5Port} \
          >> "$HOME/.tailscale/tailscaled.log" 2>&1 &
      fi
    ''
  );
}
