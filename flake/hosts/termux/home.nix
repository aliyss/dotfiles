{
  pkgs,
  config,
  lib,
  # Flake inputs arrive via extraSpecialArgs = inputs (flake/flake.nix);
  # only the ones used here need naming.
  nixpkgs,
  ...
}:
let
  sshKeys = import ../../lib/ssh-keys.nix;
  authorizedKeysFile = pkgs.writeText "authorized_keys" (lib.concatStringsSep "\n" sshKeys);
  # Same package as the desktop (flake/packages/freebuff): npm launcher shim +
  # herdr lifecycle watcher. On first run the launcher downloads the real
  # bun-compiled aarch64 binary into ~/.config/manicode/freebuff (a real file,
  # visible to native Termux) — it is glibc-dynamic, so it only runs inside the
  # chroot once nix-chroot-run bind-mounts glibc's lib at /lib (see
  # aliyss-phone/nix-install.sh).
  freebuff = pkgs.callPackage ../../packages/freebuff { };
in
{
  imports = [
    # Shared device/profile options (defines aliyss.isPhone).
    ../../home-manager/options.nix
    # Same central-theme wiring as the desktop:
    # `flake/lib/theme.nix` -> `lib/themes/termux.nix`.
    ../../home-manager/themes/default.nix
    # Single fish module shared with the desktop; phone bits are gated on
    # aliyss.isPhone inside it (writes a real config.fish; Termux can't see the
    # Nix store).
    ../../home-manager/apps/fish.nix
    # herdr (workspace manager / multiplexer): same module as the desktop,
    # minus the Hyprland-only `herdr-launch` wrapper (see apps/herdr.nix).
    ../../home-manager/apps/herdr.nix
    # Shared neovim module; the phone gets the lean core profile (theme +
    # Ctrl+hjkl navigation + telescope/treesitter/editing essentials), all
    # heavy clusters (LLM, LSP/completion, DAP, media) are desktop-only.
    ../../home-manager/apps/neovim.nix
    # Tailscale, fully declarative: nix-built binaries + the runit service
    # definition written by home.activation (see apps/tailscale.nix).
    ../../home-manager/apps/tailscale.nix
    # Declarative Android app installs from the aliyss-android-pkgs flake
    # input (defines aliyss.androidPkgs, see apps/android-pkgs.nix).
    ../../home-manager/apps/android-pkgs.nix
    # Declarative Android settings + hook services from the LOCAL
    # aliyss-android-settings repo (~/Projects; defines aliyss.androidSettings,
    # see apps/android-settings.nix). Swap the module to a flake input once the
    # repo is pushed.
    ../../home-manager/apps/android-settings.nix
  ];

  # Android apps installed declaratively from aliyss-android-pkgs: built +
  # pm-installed (as root) on every switch. Add app-ids here to install them;
  # remove an id to stop (re)installing it. See aliyss-phone/README.md.
  aliyss.androidPkgs = [
    "com.darkempire78.opencalculator"
  ];

  # Declarative Android settings + hook services (repo:
  # ~/Projects/aliyss-android-settings). Props apply via `settings put` on
  # every switch; hooks run as termux-services (runit) services named
  # android-settings-<hook>. See aliyss-phone/README.md.
  aliyss.androidSettings = {
    enable = true;

    # Apps disabled via `pm disable-user --user 0` (reversible: remove the id
    # and update-home re-enables it). Per the community Essential-Key guide
    # (z3phydev/How-to-remap-or-disable-the-Essential-Key), BOTH packages must
    # go: ntessentialspace is the space UI, but ntessentialrecorder handles
    # the key's press/capture flow — without it disabled the key still works.
    disabledApps = [
      "com.nothing.ntessentialspace"
      "com.nothing.ntessentialrecorder"
      # Replaced by the key-remap hook (its background listener would race
      # the hook for the same key events). Re-enable with enable-app if ever
      # needed: android-settings enable-app io.github.sds100.keymapper
    ];

    props = {
      "global.window_animation_scale" = "0.75";
      "global.transition_animation_scale" = "0.75";
      "global.animator_duration_scale" = "0.75";
    };
    hooks = [
      "battery-low"
      "night-dnd"
      "night-dark"
      # Keeps the Nix chroot carrying the inet group: without it every lookup
      # inside the chroot fails (git/ssh/curl cannot resolve) - see the hook.
      "chroot-dns"
      # Essential Key remap (replaces the Keymapper app entirely). Gestures
      # ported 1:1 from the Keymapper export (key_maps_20260920-202303.zip:
      # clickType 0/1/2 = short/long/double, scancode 250 = 0xfa):
      #   short  -> Termux RUN_COMMAND opening the tailscale fzf picker
      #   double -> SBB Mobile
      #   long   -> Google Wallet
      "key-remap"
    ];
    hookConfig = {
      "battery-low" = {
        THRESHOLD = "15";
        CHECK_INTERVAL = "300";
      };
      "night-dnd" = {
        NIGHT_START = "23:00";
        NIGHT_END = "07:00";
        DND_MODE = "alarms";
      };
      "night-dark" = {
        NIGHT_START = "22:00";
        NIGHT_END = "07:00";
      };
      "key-remap" = {
        SCANCODE = "00fa";
        # gpio-keys node reporting the Essential Key (getevent -pl: scancode 0xfa)
        KEY_DEVICE = "/dev/input/event0";
        # Actions run as root; see hooks/key-remap/run for the gesture logic.
        SINGLE_ACTION = "am startservice --user 0 -n com.termux/.app.RunCommandService -a com.termux.RUN_COMMAND --es com.termux.RUN_COMMAND_PATH /data/data/com.termux/files/usr/bin/fish --esa com.termux.RUN_COMMAND_ARGUMENTS '-c,/data/data/com.termux/files/home/.config/aliyss-phone/scripts/tailscale_fzf.sh'";
        DOUBLE_ACTION = "monkey -p ch.sbb.mobile.android.preview -c android.intent.category.LAUNCHER 1";
        LONG_ACTION = "monkey -p com.google.android.apps.walletnfcrel -c android.intent.category.LAUNCHER 1";
      };
    };
  };

  # Everything phone-specific (real-file configs, Tailscale/sshd, no Hyprland)
  # is gated on this flag.
  aliyss.isPhone = true;

  # Last piece of the old sync-phone.sh flow: suppress the Termux login banner.
  home.file.".hushlogin" = {
    text = "";
    force = true;
  };

  # nix-shell -p <pkg> and nix-build resolve <nixpkgs> through the channel
  # lookup (~/.nix-defexpr/channels). This install has no channel, so they
  # failed with the nixpkgs-not-found error in the Nix search path. Point
  # that lookup at the nixpkgs this flake is pinned to: the same revision as
  # the system, nothing extra to download or keep updated, and the
  # generation keeps the store path alive for the GC.
  home.file.".local/state/nix/profiles/channels/nixpkgs" = {
    source = nixpkgs.outPath;
    force = true;
  };

  # Stable aliases enforced by the `nix-chroot` helper: "$USER" is always
  # "u0_a393" (fake /etc/passwd maps it to the real Termux uid) and "$HOME" is
  # the standard Termux home. These must match so home-manager's activation
  # sanity checks pass.
  home.username = "u0_a393";
  home.homeDirectory = "/data/data/com.termux/files/home";
  home.stateVersion = "23.05";

  # The manpage builder was a proot casualty (ptrace could not emulate glibc's
  # sem_open linkat). Chroot runs the real kernel, so it could likely be
  # re-enabled, but the phone has no need for manpages.
  manual.manpages.enable = false;

  home.packages =
    with pkgs;
    [
      bat
      btop
      connect
      eza
      fd
      htop
      jq
      ripgrep
      git
      zoxide
    ]
    ++ [
      freebuff
    ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Phone sshd accepts every device's key (same pool as the NixOS boxes), so
  # every machine can reach the phone. Written as a real file because Termux
  # sshd can't see the Nix store symlink.
  home.file.".ssh/authorized_keys" = {
    source = authorizedKeysFile;
    force = true;
  };

  home.activation.copyPhoneAuthorizedKeys =
    lib.hm.dag.entryAfter
      [
        "linkGeneration"
      ]
      ''
        mkdir -p "$HOME/.ssh"
        rm -f "$HOME/.ssh/authorized_keys"
        cp ${authorizedKeysFile} "$HOME/.ssh/authorized_keys"
        chmod 600 "$HOME/.ssh/authorized_keys"
      '';

  nixpkgs.config.allowUnfree = true;
}
