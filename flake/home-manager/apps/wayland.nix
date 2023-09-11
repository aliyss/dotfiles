{ config, lib, pkgs, ... }:
let
  rev = "master"; # 'rev' could be a git rev, to pin the overlay.
  url =
    "https://github.com/nix-community/nixpkgs-wayland/archive/${rev}.tar.gz";
  waylandOverlay = (import "${
      builtins.fetchTarball {
        url = url;
        sha256 = "090dchrywa00sr27yh6wfji4jvzgciy7l281vyfdz6h64d3hwngy";
      }
    }/overlay.nix");
in {
  nixpkgs.overlays = [ waylandOverlay ];
  programs.obs-studio = { enable = true; };
  # ...
}
