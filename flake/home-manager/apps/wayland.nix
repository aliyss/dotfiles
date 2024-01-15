{ config, lib, pkgs, ... }:
let
  rev = "master"; # 'rev' could be a git rev, to pin the overlay.
  url =
    "https://github.com/nix-community/nixpkgs-wayland/archive/${rev}.tar.gz";
  waylandOverlay = (import "${
      builtins.fetchTarball {
        url = url;
        sha256 = "1y60hwga67xc1qxhfbhjyg36x2j5zs3kqyjqf6a4rs841h1i1l4n";
      }
    }/overlay.nix");
in {
  nixpkgs.overlays = [ waylandOverlay ];
  programs.obs-studio = { enable = true; };
  # ...
}
