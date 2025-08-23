{...}: {
  imports = [
    ./services/redis.nix
    ./programs/barracuda.nix
    # ./services/llama-cpp.nix
    # ./services/ollama.nix
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
}
