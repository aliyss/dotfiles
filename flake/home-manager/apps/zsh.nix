{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableAutosuggestions = true;
    syntaxHighlighting = { enable = true; };
    oh-my-zsh = {
      enable = true;
      plugins = [ "docker-compose" "docker" "git" ];
      theme = "dst";
    };
    shellAliases = {
      update-system =
        "sudo nixos-rebuild switch --flake ~/.config/flake#aliyss-bequitta";
      update-home = "home-manager switch --flake ~/.config/flake#aliyss";
    };
    initExtra = ''
      source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh;
      bindkey '^f' autosuggest-accept;
    '';
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
}
