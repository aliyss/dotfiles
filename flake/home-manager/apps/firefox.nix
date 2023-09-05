{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;
    package =
      pkgs.firefox-beta.override { cfg = { enableTridactylNative = true; }; };
    forceWayland = true;
  };
}
