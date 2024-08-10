{...}: {
  services.ollama = {
    enable = false;
    acceleration = "cuda";
  };
}
