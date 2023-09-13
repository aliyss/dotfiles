{ config, lib, pkgs, ... }:
let
  rev = "master"; # 'rev' could be a git rev, to pin the overlay.
  url =
    "https://github.com/nix-community/nixpkgs-wayland/archive/${rev}.tar.gz";
  waylandOverlay = (import "${
      builtins.fetchTarball {
        url = url;
        sha256 = "1m8r2p2f8xv6x2rl7kyaipwcsr1gp30qa6agih27p04hyz6bcw6h";
      }
    }/overlay.nix");
in {
  nixpkgs.overlays = [ waylandOverlay ];
  programs.obs-studio = { enable = true; };
  # ...
}
