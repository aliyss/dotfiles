{ config, lib, pkgs, ... }: let
  footIni = builtins.readFile ./foot.ini;
  generatedColors = config.aliyss.themeGenerators.foot;

  fullConfig = builtins.replaceStrings ["GENERATED_COLORS"] [generatedColors] footIni;
in {
  xdg.configFile."foot/foot.ini" = {
    text = fullConfig;
    force = true;
  };
}
