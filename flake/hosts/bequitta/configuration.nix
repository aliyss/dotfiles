{ pkgs, lib, ... }: {
  imports = [
    ./hardware/nvidia.nix
    ./services/redis.nix
    ./programs/programs.nix
  ];

  # NVIDIA host — enable CUDA for blender, etc. (blisspla/blade are Intel and keep false for cache.forall.systems hit)
  nixpkgs.config.cudaSupport = lib.mkForce true;

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
