{ ... }: {
  networking.networkmanager.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [80 443 25565];
    # Only allow SSH from Tailscale
    interfaces."tailscale0" = {
      allowedTCPPorts = [ 22 ];
    };
  };
}
