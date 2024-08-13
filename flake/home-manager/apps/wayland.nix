{...}: let
  rev = "master"; # 'rev' could be a git rev, to pin the overlay.
  url = "https://github.com/nix-community/nixpkgs-wayland/archive/${rev}.tar.gz";
  waylandOverlay = import "${
    builtins.fetchTarball {
      url = url;
      sha256 = "1qkpa1gnikhh0pbxvj1bgb35mwv62nmd1bhw2gf02hhya5274slk";
    }
  }/overlay.nix";
in {
  nixpkgs.overlays = [waylandOverlay];
  programs.obs-studio = {enable = true;};
  # ...
}
