{
  config,
  pkgs,
  spicetify-nix,
  ...
}: let
  spicePkgs = spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  p = config.aliyss.theme.palette;
in {
  programs.spicetify = {
    enable = true;
    theme = spicePkgs.themes.text;
    colorScheme = "oxocarbon";

    customColorScheme = {
      text               = builtins.substring 1 6 p.text;
      subtext            = builtins.substring 1 6 p.overlay0;
      main               = builtins.substring 1 6 p.base;
      sidebar            = builtins.substring 1 6 p.base;
      player             = builtins.substring 1 6 p.base;
      card               = builtins.substring 1 6 p.surface0;
      shadow             = "000000";
      selected-row       = builtins.substring 1 6 p.surface1;
      button             = builtins.substring 1 6 p.blue;
      button-active      = builtins.substring 1 6 p.blue;
      button-disabled    = builtins.substring 1 6 p.surface1;
      tab-active         = builtins.substring 1 6 p.surface1;
      notification       = builtins.substring 1 6 p.surface0;
      notification-error = builtins.substring 1 6 p.red;
      misc               = builtins.substring 1 6 p.overlay0;
    };

    enabledCustomApps = with spicePkgs.apps; [marketplace];

    enabledExtensions = with spicePkgs.extensions; [
      keyboardShortcut
      hidePodcasts
      adblock
    ];
  };
}
