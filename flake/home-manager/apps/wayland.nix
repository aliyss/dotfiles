{...}: let
  rev = "master"; # 'rev' could be a git rev, to pin the overlay.
  url = "https://github.com/nix-community/nixpkgs-wayland/archive/${rev}.tar.gz";
  waylandOverlay = import "${
    builtins.fetchTarball {
      url = url;
      sha256 = "1vjpfy3pjgz9m12lqdrycd87dgdkw04a9slza45lbajf9lbxq7p5";
    }
  }/overlay.nix";
in {
  nixpkgs.overlays = [waylandOverlay];
  programs.obs-studio = {enable = true;};
  # ...
}
