{
  pkgs,
  spicetify-nix,
  ...
}: let
  spicePkgs = spicetify-nix.legacyPackages.${pkgs.system};
in {
  programs.spicetify = {
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
