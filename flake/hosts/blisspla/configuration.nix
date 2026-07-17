{pkgs, ...}: {
  imports = [
  ];

  networking.hostName = "aliyss-blisspla";

  services = {
    xserver = {
      enable = true;
      videoDrivers = ["intel" "modesetting"];
    };
  };
}
