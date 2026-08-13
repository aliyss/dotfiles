{
  pkgs,
  config,
  lib,
  ...
}:
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
  ];

  # Everything phone-specific (real-file configs, Tailscale/sshd, no Hyprland)
  # is gated on this flag.
  aliyss.isPhone = true;

  # Last piece of the old sync-phone.sh flow: suppress the Termux login banner.
  home.file.".hushlogin" = {
    text = "";
    force = true;
  };

  # Stable aliases enforced by the `nix-proot` helper: "$USER" is always
  # "u0_a393" (fake /etc/passwd maps it to the real Termux uid) and "$HOME" is
  # the standard Termux home. These must match so home-manager's activation
  # sanity checks pass.
  home.username = "u0_a393";
  home.homeDirectory = "/data/data/com.termux/files/home";
  home.stateVersion = "23.05";

  # Under proot, home-manager's manpage builder trips over Python
  # multiprocessing (POSIX semaphores -> glibc sem_open linkat), so skip it.
  manual.manpages.enable = false;

  home.packages = with pkgs; [
    bat
    btop
    eza
    fd
    htop
    jq
    neovim
    ripgrep
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  nixpkgs.config.allowUnfree = true;
}
