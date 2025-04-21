{
  pkgs,
  spicetify-nix,
  ...
}: let
  spicePkgs = spicetify-nix.legacyPackages.${pkgs.system};
in {
  programs.spicetify = let
    # use a different version of spicetify-themes than the one provided by
    # spicetify-nix
    officialThemes = pkgs.fetchgit {
      url = "https://github.com/spicetify/spicetify-themes";
      sha256 = "sha256-HQJrCB5kN8mE4yzC6Sc0Dh7mpttoAGIx3cvlNGnkPvc=";
    };
  in {
    enable = true;
    theme = spicePkgs.themes.text;

    enabledCustomApps = with spicePkgs.apps; [marketplace];

    enabledExtensions = with spicePkgs.extensions; [
      keyboardShortcut
      hidePodcasts
      adblock
    ];
  };
}
