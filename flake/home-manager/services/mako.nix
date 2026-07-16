{config, ...}: {
  services.mako = {
    enable = true;
    extraConfig = config.aliyss.themeGenerators.mako;
    settings = {
      default-timeout = 4000;
      border-radius = 0;
    };
  };
}
