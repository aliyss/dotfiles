{
  pkgs,
  config,
  lib,
  ...
}: let
  # Default session variables
  defaultSessionVars = {
    # Emacs
    LSP_USE_PLISTS = "true";
    # Firefox
    MOZ_ENABLE_WAYLAND = "1";
    # Wine
    WINEPREFIX = "${config.home.homeDirectory}/.wine/";
    EDITOR = "nvim";
  };

  # Read the .env file safely
  envVars = builtins.foldl' (
    acc: line: let
      parts = lib.splitString "=" line;
    in
      if builtins.length parts == 2
      then acc // {"${(builtins.elemAt parts 0)}" = "${(builtins.elemAt parts 1)}";}
      else acc
  ) {} (lib.splitString "\n" "");
in {
  imports = [
    ./packages.nix
    ./apps/wayland.nix
    ./apps/tmux.nix
    ./apps/spicetify.nix
    ./apps/zsh.nix
    ./apps/yazi.nix
    ./apps/fish.nix
    ./apps/direnv.nix
    ./apps/neovim.nix
    ./apps/firefox.nix
    ./services/mako.nix
    # ./services/mbsync.nix
    # ./apps/emacs.nix
    # ./services/emacs.nix
  ];

  # Home Manager needs a bit of information about you and the paths it should manage.
  home.username = "aliyss";
  home.homeDirectory = "/home/aliyss";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.05"; # Please read the comment before changing.

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  home.sessionVariables = lib.attrsets.recursiveUpdate defaultSessionVars envVars;

  home.pointerCursor = {
    package = pkgs.simp1e-cursors;
    name = "Simp1e-Dark";
    size = 28;
    gtk.enable = true;
    x11.enable = true;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
