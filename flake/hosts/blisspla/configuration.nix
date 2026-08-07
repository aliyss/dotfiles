{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.forticlient-nixos.nixosModules.forticlient
  ];

  networking.hostName = "aliyss-blisspla";

  services = {
    xserver = {
      enable = true;
      videoDrivers = ["intel" "modesetting"];
    };
    # forticlient = {
    #   enable = true;
    #   trayAutostart = true;
    #   extraLibraries = with pkgs; [libgbm];
    #   package = inputs.forticlient-nixos.packages.x86_64-linux.forticlient.override {
    #     version = "7.4.7.1868";
    #     sha256 = "1mlwy5wzicnb2ilp39g03rji017l9x236xn7p1varlg6nv0k18pb";
    #     url = "https://repo.fortinet.com/repo/forticlient/7.4/ubuntu/pool/non-free/f/forticlient/forticlient_7.4.7.1868_amd64.deb";
    #   };
    # };
  };
}
