{...}: let
  rev = "master"; # 'rev' could be a git rev, to pin the overlay.
  url = "https://github.com/nix-community/nixpkgs-wayland/archive/${rev}.tar.gz";
  waylandOverlay = import "${
    builtins.fetchTarball {
      url = url;
      sha256 = "1pp0w3bjngjklsxqr7vpamp0b9lphwvln34b4bsf4ad942vi302x";
    }
  }/overlay.nix";
in {
  nixpkgs.overlays = [waylandOverlay];
  programs.obs-studio = {enable = true;};
  # ...
}
