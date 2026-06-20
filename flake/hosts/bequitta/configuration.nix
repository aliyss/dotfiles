{ pkgs, ... }: {
  imports = [
    ./services/redis.nix
    ./programs/programs.nix
  ];

  networking.hostName = "aliyss-bequitta";

  environment.etc."systemd/redis/librejson.so" = {
    source = ./services/redis/release/librejson.so;
    mode = "755";
  };
  environment.etc."systemd/redis/timeseries.so" = {
    source = ./services/redis/release/timeseries.so;
    mode = "755";
  };

  services.xserver = {
    enable = true;
    videoDrivers = ["nvidia"];
  };
}
