{ config, lib, pkgs, ... }:
let
  theme = config.aliyss.themeGenerators.youtube-music;
in {
  xdg.configFile."YouTube Music/theme.css".text = theme;
}
