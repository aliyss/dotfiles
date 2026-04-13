{pkgs, ...}: {
  imports = [
    ./services/redis.nix
    ./programs/programs.nix
    # ./services/llama-cpp.nix
    ./services/ollama.nix
    # ./services/neo4j.nix
  ];

  # HOSTNAME
  networking.hostName = "aliyss-bequitta";

  environment.etc."systemd/redis/librejson.so" = {
    source = ./services/redis/release/librejson.so;
    mode = "755";
  };
  environment.etc."systemd/redis/timeseries.so" = {
    source = ./services/redis/release/timeseries.so;
    mode = "755";
  };

  services = {
    xserver = {
      enable = true;
      videoDrivers = ["nvidia"];
    };
  };

  environment.systemPackages = with pkgs; [
    (distrho-ports.override {plugins = ["tal-vocoder-2"];})
    carla # The host to run it live
    vmpk # The keyboard to play the notes
  ];
}
