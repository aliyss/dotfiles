{ ... }: {
  services.devmon.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.pcscd.enable = true;
  services.teamviewer = {
    enable = true;
  };
  services.hardware.openrgb.enable = true;
}
