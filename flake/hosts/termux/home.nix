{
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [
    # Reuse the exact same central-theme wiring the desktop home-manager uses:
    # `flake/lib/theme.nix` -> `lib/themes/termux.nix` / `phone-fish.nix`.
    ../../home-manager/themes/default.nix
  ];

  # Write `.termux/colors.properties` and `.config/fish/config.fish` on the
  # phone from the shared theme generators.
  aliyss.phone.enable = true;

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
    jq
    ripgrep
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  nixpkgs.config.allowUnfree = true;
}