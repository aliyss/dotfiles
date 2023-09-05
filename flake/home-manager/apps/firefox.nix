{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;
    package = pkgs.firefox-unwrapped.override {
      cfg = { enableTridactylNative = true; };
    };
  };
}
