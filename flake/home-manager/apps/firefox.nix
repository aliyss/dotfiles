{ pkgs, config, lib, ... }@args:

let
  defaultProfile = import ./firefox/profiles/default.nix args;

  defaultConfigJS = (builtins.readFile ./firefox/config/config.js);
  defaultAutoConfigJS = (builtins.readFile ./firefox/config/autoconfig.js);

  firefox-override = pkgs.firefox-wayland.overrideAttrs (self: {
    name = "firefox-override";

    buildCommand = self.buildCommand + ''
      set -euo pipefail

      ${lib.concatStringsSep "\n" (map (outputName: ''
        echo "Copying output ${outputName}"
        set -x
        set +x
      '') (self.outputs or [ "out" ]))}

      cp "${
        pkgs.writeText "$out/config.js" ("${defaultConfigJS}")
      }" "$out"/lib/firefox/config.js
      cp "${
        pkgs.writeText "$out/autoconfig.js" ("${defaultAutoConfigJS}")
      }" "$out"/lib/firefox/defaults/pref/autoconfig.js
    '';

  });

  defaultFirefox = firefox-override.override {
    cfg = {
      enableGnomeExtensions = true;
      autoConfig = ''
        pref("general.config.filename", "config.js");
        pref("general.config.obscure_value", 0);
        pref("general.config.sandbox_enabled", false);
      '';
      nativeMessagingHosts.packages = [ pkgs.tridactyl-native ];
    };
    extraPolicies = {
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableTelemetry = true;
      FirefoxHome = {
        Pocket = false;
        Snippets = false;
      };
      UserMessaging = {
        ExtensionRecommendations = false;
        SkipOnboarding = true;
      };
      OfferToSaveLoginsDefault = false;
    };
    extraPrefsFiles = (args.extraPrefsFiles or [ ]) ++ [
      # make sure that autoplay is enabled by default for the audio test
    ];
  };

in {

  imports = [
    ./firefox/extensions/tridactyl.nix
    ./firefox/extensions/ublock.nix
    ./firefox/extensions/permissions.nix
  ];

  programs.firefox = {
    enable = true;
    package = defaultFirefox;
    profiles = { default = defaultProfile; };
  };

}
