{lib, ...}: {
  services.devmon.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.pcscd.enable = true;
  services.teamviewer = {
    enable = true;
  };
  services.hardware.openrgb.enable = true;
  services.tailscale.enable = true;

  # SSH limited to Tailscale via firewall (see networking.nix)
  services.openssh = {
    enable = true;
    ports = [22];
    openFirewall = false; # Handled per-interface in networking.nix
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = lib.mkForce "no";
      KbdInteractiveAuthentication = false;
      MaxAuthTries = 3;
      LoginGraceTime = 30;
      ClientAliveInterval = 60;
      ClientAliveCountMax = 3;
      UseDns = false;
      AllowUsers = ["aliyss"];
    };
  };
}
