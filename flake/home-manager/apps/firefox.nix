{ pkgs, ... }:

{
  programs.firefox-beta = {
    enable = true;
    package = pkgs.firefox-unwrapped.override {
      cfg = { enableTridactylNative = true; };
    };
  };
}
