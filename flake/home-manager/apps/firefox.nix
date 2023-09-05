{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;
    package =
      pkgs.firefox-beta.override { cfg = { enableTridactylNative = true; }; };
    profiles = {
      default = {
        extensions = with pkgs.nur.repos.rycee.firefox-addons;
          [ privacy-badger ];
      };
    };
  };
}
