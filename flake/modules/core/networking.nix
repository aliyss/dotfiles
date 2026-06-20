{ ... }: {
  networking.networkmanager.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [80 443 25565 22922];
  };
}
