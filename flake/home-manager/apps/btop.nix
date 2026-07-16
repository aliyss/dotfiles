{config, ...}: {
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "oxocarbon.theme";
    };
  };

  xdg.configFile."btop/btop.conf".force = true;

  xdg.configFile."btop/themes/oxocarbon.theme" = {
    text = config.aliyss.themeGenerators.btop;
  };
}
