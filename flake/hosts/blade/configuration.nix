{...}: {
  imports = [
    # ./programs/adb.nix
    ./services/openssh.nix
  ];

  # HOSTNAME
  networking.hostName = "aliyss-blade";

  services = {
    xserver = {
      enable = true;
      videoDrivers = ["intel" "modesetting"];
    };
  };
}
