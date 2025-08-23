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
      update-system-bequitta = "sudo nixos-rebuild switch --flake ~/.config/flake#aliyss-bequitta";
      update-system-blade = "sudo nixos-rebuild switch --flake ~/.config/flake#aliyss-blade";
      update-home = "home-manager switch --flake ~/.config/flake#aliyss";
      upgrade-flake = "nix flake update ~/.config/flake";
      start-camera = "scrcpy --video-source=camera --no-audio --camera-id=1 --v4l2-sink=/dev/video0 --no-video-playback";
      bw-unlock = "export BW_SESSION=$(command bw unlock --raw)";
      bw = "[ -z \"$BW_SESSION\" ] && bw-unlock; command bw";
      rbw = "DISPLAY= command rbw";
      no-console-rbw = "command rbw";
    };
    sessionVariables = {ZSH_TMUX_AUTOSTART = "true";};
    initContent = ''
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
}
