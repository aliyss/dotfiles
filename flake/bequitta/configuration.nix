{...}: {
  imports = [
    ./services/redis.nix
    ./services/ollama.nix
    # ./services/neo4j.nix
  ];

  environment.etc."systemd/redis/librejson.so" = {
    source = ./services/redis/release/librejson.so;
    mode = "755";
  };
}
