# DEPRECATED: unified LLM is now services.llama-cpp in modules/profiles/llm.nix
# ollama kept disabled — not imported. Enable here only if you need ollama alongside llama-cpp.
{
  inputs,
  system,
  pkgs,
  ...
}: {
  # nixpkgs.overlays = [overlay-unstable];
  nixpkgs.config.cudaSupport = true;
  services.ollama = {
    package = pkgs.ollama-cuda;
    enable = false;
  };
}
