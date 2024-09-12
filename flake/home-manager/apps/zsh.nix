{pkgs, ...}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting = {enable = false;};
    oh-my-zsh = {
      enable = true;
      plugins = ["docker-compose" "docker" "git" "tmux"];
      theme = "dst";
    };
    shellAliases = {
      update-system = "sudo nixos-rebuild switch --flake ~/.config/flake#aliyss-bequitta";
      update-home = "home-manager switch --flake ~/.config/flake#aliyss";
      upgrade-flake = "sudo nix flake update ~/.config/flake";
      start-camera = "scrcpy --video-source=camera --no-audio --camera-id=1 --v4l2-sink=/dev/video0 --no-video-playback";
    };
    sessionVariables = {ZSH_TMUX_AUTOSTART = "true";};
    initExtra = ''
      source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh;
      bindkey '^f' autosuggest-accept;
      bindkey -v

      if [[ "$TERM" == "dumb" ]]
      then
        unsetopt zle
        unsetopt prompt_cr
        unsetopt prompt_subst
        if whence -w precmd >/dev/null; then
            unfunction precmd
        fi
        if whence -w preexec >/dev/null; then
            unfunction preexec
        fi
        PS1='$ '
      fi

    '';
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
}
