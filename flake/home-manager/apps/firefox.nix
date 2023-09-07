{ pkgs, config, lib, ... }@args:

let
  buildFirefoxXpiAddon =
    config.nur.repos.rycee.firefox-addons.buildFirefoxXpiAddon;
  defaultProfile = import ./firefox/profiles/default.nix args;
in {

  imports = [
    ./firefox/extensions/tridactyl.nix
    ./firefox/extensions/ublock.nix
    ./firefox/extensions/permissions.nix
  ];

  programs.firefox = {
    enable = true;
    package = pkgs.firefox-wayland.override {
      cfg = {
        enableGnomeExtensions = true;
        enableTridactylNative = true;
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
    };
    profiles = { default = defaultProfile; };
  };
}
