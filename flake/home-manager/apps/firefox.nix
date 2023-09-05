{ pkgs, lib, nur, ... }:

let
  nur-no-pkgs = import (builtins.fetchTarball {
    url = "https://github.com/nix-community/NUR/archive/master.tar.gz";
    sha256 = "01nazr93wsv64i9b36fniz8cy9mjrfzkjfdpnmaawg7jma63idnl";
  }) { };
in {

  imports = lib.attrValues nur-no-pkgs.repos.moredhel.hmModules.rawModules;

  programs.firefox = {
    enable = true;
    package =
      pkgs.firefox-beta.override { cfg = { enableTridactylNative = true; }; };
    profiles = {
      default = {
        extensions = with nur.repos.rycee.firefox-addons; [ privacy-badger ];
      };
    };
  };
}
