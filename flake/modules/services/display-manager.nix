{ ... }: {
  services.displayManager.gdm = {
    enable = true;
  };

  services.xserver = {
    enable = true;
    xkb = {
      variant = "colemak_dh_iso";
      layout = "us";
    };
  };
}
