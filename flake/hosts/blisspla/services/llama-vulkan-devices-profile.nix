# DEPRECATED: merged into modules/profiles/llm.nix (conditional environment.systemPackages)
# Not imported from flake.nix anymore — profile module handles Vulkan helper + package exposure.
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = [
    config.services.llama-cpp.package
  ];
}
