{lib, ...}: {
  services.devmon.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.pcscd.enable = true;
  services.teamviewer = {
    enable = true;
  };
  services.hardware.openrgb.enable = true;

  # Mosh for resilient phone roaming (Wi-Fi ↔ LTE handoff without dropping
  # herdr). `programs.mosh.openFirewall` defaults to true; we set it
  # explicitly so UDP 60000-61000 is opened by the firewall even if NixOS
  # ever flips the default. See `./phone-remote-access.md`.
  programs.mosh.enable = true;
  programs.mosh.openFirewall = true;

  # Phone SSH backdoor. Port 22922 is already allowed by networking.nix.
  # PasswordAuthentication is left enabled so the phone can connect while
  # the user copies their public key over (see phone-remote-access.md).
  #
  # PermitRootLogin uses `lib.mkForce` so this hardened "no" wins even when
  # a per-host openssh.nix (e.g. `flake/hosts/blade/services/openssh.nix`)
  # tries to override it with a weaker value.
  services.openssh = {
    enable = true;
    ports = [22922];
    openFirewall = false; # 22922 is already in networking.firewall.allowedTCPPorts.
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = lib.mkForce "no";
      KbdInteractiveAuthentication = false;
      MaxAuthTries = 3;
      LoginGraceTime = 30;
      ClientAliveInterval = 60;
      ClientAliveCountMax = 3;
      UseDns = false; # Skip PTR reverse-lookup; phone LAN IPs won't reverse-resolve.
      AllowUsers = ["aliyss"];
    };
  };
}
