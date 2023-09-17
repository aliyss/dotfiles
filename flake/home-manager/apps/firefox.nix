{ pkgs, config, lib, ... }@args:

let
  buildFirefoxXpiAddon =
    config.nur.repos.rycee.firefox-addons.buildFirefoxXpiAddon;
  defaultProfile = import ./firefox/profiles/default.nix args;

  defaultConfigJS = (builtins.readFile ./firefox/config/config.js);

  defaultFirefox = pkgs.firefox-wayland.override {
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

  firefox-override = defaultFirefox.overrideAttrs (old: {
    name = "firefox-override";

    # Using `buildCommand` replaces the original packages build phases.
    buildCommand = ''
      set -euo pipefail

      ${
      # Copy original files, for each split-output (`out`, `dev` etc.).
      # E.g. `${package.dev}` to `$dev`, and so on. If none, just "out".
      # Symlink all files from the original package to here (`cp -rs`),
      # to save disk space.
      # We could alternatiively also copy (`cp -a --no-preserve=mode`).
      lib.concatStringsSep "\n" (map (outputName: ''
        echo "Copying output ${outputName}"
        set -x
        cp -rs --no-preserve=mode "${
          defaultFirefox.${outputName}
        }" "''$${outputName}"
        set +x
      '') (old.outputs or [ "out" ]))}

      # Example change:
      # Change `usage:` to `USAGE:` in a shell script.
      # Make the file to be not a symlink by full copying using `install` first.
      # This also makes it writable (files in the nix store have `chmod -w`).
      cp "${
        pkgs.writeText "$out/config.js" ("${defaultConfigJS}")
      }" "$out"/lib/firefox/config.js
      cp "${
        pkgs.writeText "$out/autoconfig.js" ("${defaultConfigJS}")
      }" "$out"/lib/firefox/defaults/pref/autoconfig.js
    '';

  });

in {

  imports = [
    ./firefox/extensions/tridactyl.nix
    ./firefox/extensions/ublock.nix
    ./firefox/extensions/permissions.nix
  ];

  programs.firefox = {
    enable = true;
    package = firefox-override;
    profiles = { default = defaultProfile; };
  };

}
