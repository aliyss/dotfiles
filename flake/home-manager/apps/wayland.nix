{ config, lib, pkgs, ... }:
let
  rev = "master"; # 'rev' could be a git rev, to pin the overlay.
  url =
    "https://github.com/nix-community/nixpkgs-wayland/archive/${rev}.tar.gz";
  waylandOverlay = (import "${
      builtins.fetchTarball {
        url = url;
        sha256 = "1lds2rnk7zz1gadvq1b1b84an580yd4p7a0g0mnrsrkf71b9vqry";
      }
    }/overlay.nix");
in {
  nixpkgs.overlays = [ waylandOverlay ];
  programs.obs-studio = { enable = true; };
  # ...
}
