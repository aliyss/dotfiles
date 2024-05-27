{...}: {
  imports = [
    ./services/redis.nix
    ./services/ollama.nix
  ];

  environment.etc."systemd/redis/librejson.so" = {
    source = ./services/redis/release/librejson.so;
    mode = "755";
  };
}
