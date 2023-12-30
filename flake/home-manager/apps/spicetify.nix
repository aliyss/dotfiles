{ pkgs, spicetify-nix, ... }:
let spicePkgs = spicetify-nix.packages.${pkgs.system}.default;
in {
  imports = [ spicetify-nix.homeManagerModule ];

  programs.spicetify = let
    # use a different version of spicetify-themes than the one provided by
    # spicetify-nix
    officialThemes = pkgs.fetchgit {
      url = "https://github.com/spicetify/spicetify-themes";
      sha256 = "sha256-3s6sRuOeSxJT7G4hol0zIX1fHnkf7cEByV8xt9TVgtc=";
    };
  in {
    enable = true;
    theme = {
      name = "text";
      src = officialThemes;
      appendName = true; # theme is located at "${src}/text" not just "${src}"

      # changes to make to config-xpui.ini for this theme:
      patches = {
        "xpui.js_find_8008" = ",(\\w+=)56,";
        "xpui.js_repl_8008" = ",\${1}32,";
      };
      injectCss = true;
      replaceColors = true;
      overwriteAssets = true;
      sidebarConfig = true;
    };

    enabledCustomApps = with spicePkgs.apps; [ marketplace ];

    enabledExtensions = with spicePkgs.extensions; [
      fullAppDisplay
      shuffle
      keyboardShortcut
      hidePodcasts
      adblock
    ];
  };
}
