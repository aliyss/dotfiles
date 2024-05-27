{pkgs, ...}: {
  programs.tmux = {
    enable = true;
    shell = "${pkgs.fish}/bin/fish";
    keyMode = "vi";
    newSession = true;
    escapeTime = 0;
    baseIndex = 1;
    plugins = with pkgs; [
      # {
      #   plugin = tmuxPlugins.catppuccin;
      #   extraConfig = ''
      #     set -g @catppuccin_flavour 'frappe'
      #     set -g @catppuccin_window_tabs_enabled on
      #     set -g @catppuccin_date_time "%H:%M"
      #   '';
      # }
      # {
      #   plugin = tmuxPlugins.resurrect;
      #   extraConfig = ''
      #     set -g @resurrect-capture-pane-contents 'on'
      #   '';
      # }
      # {
      #   plugin = tmuxPlugins.continuum;
      #   extraConfig = ''
      #     set -g @continuum-restore 'on'
      #     set -g @continuum-boot 'on'
      #     set -g @continuum-save-interval '10'
      #   '';
      # }
      {plugin = tmuxPlugins.sensible;}
      {plugin = tmuxPlugins.vim-tmux-navigator;}
      {plugin = tmuxPlugins.cpu;}
      {plugin = tmuxPlugins.better-mouse-mode;}
    ];
    extraConfig = ''
      set -g status-right '#[fg=color15] #{cpu_percentage}  %H:%M '
      set-option -g history-limit 10000


      set-option -sa terminal-features ',fish*:RGB'
      set-option -sa terminal-overrides ",xterm*:Tc"

      unbind C-b
      set -g prefix C-Space
      bind C-Space send-prefix

      set-option -g status-style default
      set-option -g status-position top
    '';
  };
}
