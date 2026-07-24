{config, pkgs, ...}: {
  programs.yazi = {
    enable = true;
    plugins = {
      sshfs = {
        package = pkgs.yaziPlugins.sshfs;
        setup = true;
      };
    };
    keymap = {
      mgr.prepend_keymap = [
        {
          on = [ "g" "s" ];
          run = "plugin sshfs -- menu";
          desc = "Open SSHFS options";
        }
      ];
    };
    shellWrapperName = "y";
    enableZshIntegration = true;
  };

  xdg.configFile."yazi/theme.toml" = {
    text = config.aliyss.themeGenerators.yazi;
  };
}
