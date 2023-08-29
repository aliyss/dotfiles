{ pkgs, lib, builtins, ... }:
let
  openrgb-rules = builtins.fetchurl {
    url =
      "https://gitlab.com/CalcProgrammer1/OpenRGB/-/raw/master/60-openrgb.rules";
  };
in { services.udev.extraRules = builtins.readFile openrgb-rules; }
