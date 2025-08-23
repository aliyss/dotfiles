{pkgs, ...}: let
  catppuccin-fish = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "fish";
    rev = "0ce27b518e8ead555dec34dd8be3df5bd75cff8e";
    hash = "sha256-Dc/zdxfzAUM5NX8PxzfljRbYvO9f9syuLO8yBr+R3qg=";
  };
in {
  xdg.configFile."fish/themes/Catppuccin Latte.theme".source = "${catppuccin-fish}/themes/Catppuccin Latte.theme";
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting
      fish_vi_key_bindings

      if status is-interactive
        and not set -q TMUX
            exec tmux attach || tmux new
      end

      if [ "$INSIDE_EMACS" = 'vterm' ]
         set fish_cursor_default     block      blink
         set fish_cursor_insert      line       blink
         set fish_cursor_replace_one underscore blink
         set fish_cursor_visual      block
         function clear
             vterm_printf "51;Evterm-clear-scrollback";
             tput clear;
         end
      end

      if status is-interactive
        set fish_cursor_default     block      blink
        set fish_cursor_insert      line       blink
        set fish_cursor_replace_one underscore blink
        set fish_cursor_visual      block

        function fish_user_key_bindings
          # Execute this once per mode that emacs bindings should be used in
          fish_default_key_bindings -M insert
          fish_vi_key_bindings --no-erase insert
        end
      end

      direnv hook fish | source
    '';
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
    plugins = [
      # {
      #   name = "fzf";
      #   src = pkgs.fishPlugins.fzf.src;
      # }
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

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };
}
