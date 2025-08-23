{
  inputs,
  system,
  pkgs,
  ...
}: {
  # nixpkgs.overlays = [overlay-unstable];
  nixpkgs.config.cudaSupport = true;
  services.ollama = {
    # package = pkgs.unstable-ollama.ollama-cuda;
    enable = true;
    acceleration = "cuda";
  };
}
