{ pkgs, config, lib, ... }@args:

let
  buildFirefoxXpiAddon =
    config.nur.repos.rycee.firefox-addons.buildFirefoxXpiAddon;
  defaultProfile = import ./firefox/profiles/default.nix args;
  defaultConfigJS =
    "/home/aliyss/.config/flake/home-manager/apps/firefox/config";

  firefox-patched = (import ./firefox/firefox-patched.nix);

  firefox-wayland = pkgs.wrapFirefox (firefox-patched) { };

  defaultFirefox = firefox-wayland.override {
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
