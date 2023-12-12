{ pkgs, lib, ... }:

{
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "minecraft-server" ];
  programs.minecraft-server = { enable = true; };
}
