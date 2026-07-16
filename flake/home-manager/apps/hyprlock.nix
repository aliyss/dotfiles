{config, ...}: {
  xdg.configFile."hypr/hyprlock.conf" = {
    text = config.aliyss.themeGenerators.hyprlock;
    force = true;
  };
}
