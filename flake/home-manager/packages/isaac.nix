{ pkgs, ... }:
let
  freebuff = pkgs.callPackage ../../packages/freebuff { };
in
with pkgs; [
  bun
  jq
  ripgrep
  fd
  gh
  opencode
  freebuff
]
