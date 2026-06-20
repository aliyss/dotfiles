{ pkgs, ... }: {
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [
    "i2c-dev"
    "i2c-piix4"
    "v4l2loopback"
    "snd-aloop"
  ];
  boot.extraModulePackages = with pkgs; [
    linuxPackages.v4l2loopback
  ];
}
