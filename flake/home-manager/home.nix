{ config, lib, pkgs, ... }: {
  imports = [
    ./packages.nix
    ./apps/wayland.nix
    ./apps/tmux.nix
    ./apps/spicetify.nix
    ./apps/zsh.nix
    ./apps/emacs.nix
    ./apps/neovim.nix
    ./apps/firefox.nix
    ./services/emacs.nix
    ./services/mako.nix
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
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

  home.sessionVariables = {
    # Emacs
    LSP_USE_PLISTS = "true";
    # Firefox
    MOZ_ENABLE_WAYLAND = 1;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

}
