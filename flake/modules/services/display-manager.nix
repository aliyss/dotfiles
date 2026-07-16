{ pkgs, ... }: {
  services.displayManager.gdm = {
    enable = false;
  };

  services.xserver = {
    enable = true;
    xkb = {
      layout = "ga,de";
      options = "grp:alt_space_toggle";
    };
    xkb.extraLayouts.ga = {
      description = "German (Geniusnessness)";
      languages = [ "de" ];
      symbolsFile = ./xkb/ga;
    };
  };
}
