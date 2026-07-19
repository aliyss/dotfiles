{...}: {
  # Reverting blade to standard SSH settings, handled by shared misc.nix if imported, 
  # or kept standard here.
  services.openssh = {
    enable = true;
    ports = [22];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      UseDns = false;
      AllowUsers = ["aliyss"];
    };
  };
}
