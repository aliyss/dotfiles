{
  pkgs,
  config,
  lib,
  hyprland,
  hyprland-plugins,
  hyprland-dynamic-cursors,
  hyprland-hyprspace,
  tidalcycles-nix,
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
  envFile = ../.env;
  envFileContent =
    if builtins.pathExists envFile
    then builtins.readFile envFile
    else "";
  envVars = builtins.foldl' (
    acc: line: let
      parts = lib.splitString "=" line;
    in
      if builtins.length parts == 2
      then acc // {"${(builtins.elemAt parts 0)}" = "${(builtins.elemAt parts 1)}";}
      else acc
  ) {} (lib.splitString "\n" envFileContent);
in {
  imports = [
    ./options.nix
    tidalcycles-nix.homeManagerModules.default
    ./packages.nix

    ./apps/wayland.nix
    ./apps/tmux.nix
    ./apps/wlr-which-key.nix
    # ./apps/spicetify.nix
    ./apps/yazi.nix
    ./apps/fish.nix
    ./apps/direnv.nix
    ./apps/neovim.nix
    ./apps/firefox.nix
    ./apps/tidalcycles.nix

    ./services/mako.nix
    ./services/activity-watcher.nix

    # ./services/mbsync.nix
    # ./apps/emacs.nix
    # ./services/emacs.nix
    ../local.nix
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

  home.sessionVariables =
    lib.attrsets.recursiveUpdate defaultSessionVars envVars
    // {
      XKB_CONFIG_EXTRA_PATH = "${config.home.homeDirectory}/.config/xkb";
    };

  home.pointerCursor = {
    package = pkgs.simp1e-cursors;
    name = "Simp1e-Dark";
    size = 28;
    gtk.enable = true;
    x11.enable = true;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager = {
    enable = true;
  };

  nixpkgs.config.permittedInsecurePackages = [
    "qtwebengine-5.15.19"
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    package = hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    plugins = [
      # hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.hyprexpo
      # hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.hyprscrolling
      # hyprland-dynamic-cursors.packages.${pkgs.stdenv.hostPlatform.system}.hypr-dynamic-cursors
      # hyprland-hyprspace.packages.${pkgs.stdenv.hostPlatform.system}.Hyprspace
    ];
    # configType = "lua";
    # extraConfig = ''
    #   require("~/.config/hypr/lua_config/hyprland_source.lua")
    # '';
    extraConfig = ''
      source = ~/.config/hypr/hyprland_source.conf
    '';
  };

  nixpkgs.config.allowUnfree = true;
}
