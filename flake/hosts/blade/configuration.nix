{...}: {
  imports = [
    ./programs/adb.nix
    ./programs/hyprlock.nix
  ];

  # HOSTNAME
  networking.hostName = "aliyss-blade";
}
