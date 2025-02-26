{
  inputs,
  system,
  pkgs,
  ...
}: let
  overlay-unstable = final: prev: {
    unstable-ollama = import inputs.old-ollama-nixpkgs {
      system = system;
      config = {
        allowUnfree = true;
      };
    };
  };
in {
  nixpkgs.overlays = [overlay-unstable];
  nixpkgs.config.cudaSupport = true;
  services.ollama = {
    package = pkgs.unstable-ollama.ollama-cuda;
    enable = true;
    acceleration = "cuda";
  };
}
