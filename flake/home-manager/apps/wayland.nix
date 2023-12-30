{ config, lib, pkgs, ... }:
let
  rev = "master"; # 'rev' could be a git rev, to pin the overlay.
  url =
    "https://github.com/nix-community/nixpkgs-wayland/archive/${rev}.tar.gz";
  waylandOverlay = (import "${
      builtins.fetchTarball {
        url = url;
        sha256 = "0k2pyjckvnqmqa35q8bh7imqb8mmc4h6pjdmm5aij83idqbyr7l8";
      }
    }/overlay.nix");
in {
  nixpkgs.overlays = [ waylandOverlay ];
  programs.obs-studio = { enable = true; };
  # ...
}
