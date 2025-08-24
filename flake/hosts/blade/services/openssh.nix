{...}: {
  services.openssh = {
    enable = true;
    ports = [22922];
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "prohibit-password";
      UseDns = true;
      AllowUsers = ["aliyss"];
    };
  };
}
