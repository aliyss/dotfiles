{ config, lib, pkgs, ... }:
{
  environment.systemPackages = [
    config.services.llama-cpp.package
  ];
}
