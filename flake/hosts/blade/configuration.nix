{...}: {
  imports = [
    ./programs/adb.nix
    ./programs/hyprlock.nix
    ./services/openssh.nix
  ];

  # HOSTNAME
  networking.hostName = "aliyss-blade";
}
