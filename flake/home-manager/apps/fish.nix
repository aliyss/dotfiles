{
  config,
  pkgs,
  lib,
  ...
}:
let
  isPhone = config.aliyss.isPhone;

  # ── Shared init (greeting, vi mode, cursor) ──────────────────────────────
  baseInit = ''
    set fish_greeting
    fish_vi_key_bindings

    if status is-interactive
      set fish_cursor_default     block      blink
      set fish_cursor_insert      line       blink
      set fish_cursor_replace_one underscore blink
      set fish_cursor_visual      block

      function fish_user_key_bindings
        fish_default_key_bindings -M insert
        fish_vi_key_bindings --no-erase insert
      end
    end
  '';

  # ── Herdr attach (both) ─────────────────────────────────────────────────
  # Herdr is the multiplexer. Every interactive shell — desktop panes, every
  # fresh SSH session, every Termux shell — attaches to its per-user herdr
  # daemon over its Unix socket. `herdr-workspace` (apps/herdr.nix) starts the
  # daemon if it isn't running, lands on a workspace, and execs the herdr client.
  herdrInit = ''
    if status is-interactive
      and not set -q HERDR_ENV
      and command -q herdr-workspace
      exec herdr-workspace "${if isPhone then "main" else "aliyss-termux"}"
    end

    if set -q HERDR_ENV
      command herdr terminal title set "herdr" >/dev/null 2>&1
    end
  '';

  # ── Desktop-only init (emacs vterm, direnv) ─────────────────────────────
  desktopInit = ''
    if [ "$INSIDE_EMACS" = 'vterm' ]
      set fish_cursor_default     block      blink
      set fish_cursor_insert      line       blink
      set fish_cursor_replace_one underscore blink
      set fish_cursor_visual      block

      function clear
        vterm_printf "51;Evterm-clear-scrollback"
        tput clear
      end
    end

    direnv hook fish | source
  '';

  # ── Phone-only init (sshd) ──────────────────────────────────────────────
  # nvim/htop/etc. are nix-managed (home.packages on the phone); no `pkg install`.
  phoneInit = ''
    # Start SSH daemon if not running
    if status is-interactive
      and not pgrep -x "sshd" >/dev/null
      sshd
    end
  '';

  # ── Aliases ─────────────────────────────────────────────────────────────
  # SSH shortcuts for every device, available on all machines (each device
  # reaches every other one over the tailnet).
  sshAliases = {
    ssh-blisspla = "ssh -p 22 aliyss@aliyss-blisspla";
    ssh-bequitta = "ssh -p 22 aliyss@aliyss-bequitta";
    ssh-blade = "ssh -p 22 aliyss@aliyss-blade";
    ssh-termux = "ssh -p 8022 aliyss@aliyss-termux";
  };

  desktopAliases = {
    update-system = "$HOME/.config/flake/update-system";
    ubequitta = "$HOME/.config/flake/update-system -s bequitta";
    ublade = "$HOME/.config/flake/update-system -s blade";
    update-home = "home-manager switch --flake ~/.config/flake#aliyss";
    upgrade-flake = "nix flake update --flake ~/.config/flake";
    start-camera = "scrcpy --video-source=camera --no-audio --camera-id=1 --v4l2-sink=/dev/video0 --no-video-playback";
    bw-unlock = "export BW_SESSION=$(command bw unlock --raw)";
    bw = "[ -z \"$BW_SESSION\" ] && bw-unlock; command bw";
    rbw = "DISPLAY= command rbw";
    no-console-rbw = "command rbw";
  };

  phoneAliases = {
    # tailscale/tailscaled are nix-built (flake/packages/tailscale-termux) and
    # wrapped into ~/.local/bin; the CLI already defaults its socket to
    # ~/.tailscale/tailscaled.sock. `tailscale-cli` is kept as a compat alias
    # for the old bropines .deb command name.
    tailscale-cli = "tailscale";
    update-system = "bash ~/.config/aliyss-phone/update-system.sh";
    update-home = "bash ~/.config/aliyss-phone/update-home.sh";
    update-phone = "bash ~/.config/aliyss-phone/update-home.sh";
    upgrade-flake = "nix flake update --flake ~/.config/flake";
    # Build + pm-install an Android app from aliyss-android-pkgs via the
    # repo's installer (aliyss-android-pkgs scripts/install.sh, packaged as
    # .#android-install), e.g. `install-app org.videolan.vlc`. -d = on-device
    # (no adb), -f = build from the dotfiles flake (pins the input).
    install-app = "android-install -d -f ~/.config/flake";
    uninstall-app = "android-install -d -f ~/.config/flake -u";
  };

  aliases = sshAliases // (if isPhone then phoneAliases else desktopAliases);

  # The phone's config.fish is a plain real file (native Termux can't follow
  # Nix-store symlinks), so aliases are inlined as `alias` lines there.
  renderAliases = builtins.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value: "alias ${name}=\"${value}\"") aliases
  );

  # zoxide: nix-built and wrapped into ~/.local/bin, which
  # conf.d/nix-termux.fish already added to PATH. `--cmd cd` makes zoxide take
  # over `cd` (same as the desktop's programs.zoxide); zoxide 0.10 can't emit
  # a second command itself, so re-alias `z`/`zi` onto the internal functions
  # it still defines. `zi`/`cdi` (interactive) need fzf, which is not on the
  # phone.
  zoxideInit = ''
    if command -q zoxide
      zoxide init fish --cmd cd | source
      alias z=__zoxide_z
      alias zi=__zoxide_zi
    end
  '';

  # Single source of truth for the phone's whole ~/.config/fish/config.fish.
  # herdr attach must come last: `exec herdr-workspace` replaces the shell, so
  # anything before it (sshd autostart) still runs.
  phoneFishText = ''
    ${baseInit}
    ${renderAliases}
    ${zoxideInit}
    ${phoneInit}
    ${herdrInit}
  '';

  desktopFishInit = ''
    ${baseInit}
    ${herdrInit}
    ${desktopInit}
  '';
in
{
  # ── Desktop: home-manager's programs.fish (store symlinks are fine) ──────
  programs.fish = lib.mkIf (!isPhone) {
    enable = true;
    interactiveShellInit = desktopFishInit;
    shellAliases = aliases;
    plugins = [
      {
        name = "fzf";
        src = pkgs.fishPlugins.fzf-fish.src;
      }
      {
        name = "catppuccin-fish";
        src = pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "fish";
          rev = "0ce27b518e8ead555dec34dd8be3df5bd75cff8e";
          sha256 = "sha256-Dc/zdxfzAUM5NX8PxzfljRbYvO9f9syuLO8yBr+R3qg=";
        };
      }
      {
        name = "forgit";
        src = pkgs.fishPlugins.forgit.src;
      }
      {
        name = "colored-man-pages";
        src = pkgs.fishPlugins.colored-man-pages.src;
      }
      {
        name = "done";
        src = pkgs.fishPlugins.done.src;
      }
      {
        name = "z";
        src = pkgs.fishPlugins.z.src;
      }
    ];
  };

  programs.fzf = lib.mkIf (!isPhone) {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    colors = config.aliyss.themeGenerators.fzf;
  };

  # ── Phone: a real config.fish (Termux can't see the Nix store) ───────────
  home.file.".config/fish/config.fish" = lib.mkIf isPhone {
    text = phoneFishText;
    force = true;
  };

  home.activation.copyPhoneFishConfig = lib.mkIf isPhone (
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      mkdir -p "$HOME/.config/fish"
      rm -f "$HOME/.config/fish/config.fish"
      cp ${pkgs.writeText "config.fish" phoneFishText} "$HOME/.config/fish/config.fish"
      chmod 644 "$HOME/.config/fish/config.fish"
    ''
  );
}
