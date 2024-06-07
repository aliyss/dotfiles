{...}: let
  rev = "master"; # 'rev' could be a git rev, to pin the overlay.
  url = "https://github.com/nix-community/nixpkgs-wayland/archive/${rev}.tar.gz";
  waylandOverlay = import "${
    builtins.fetchTarball {
      url = url;
      sha256 = "1pbs04aqbgvkc07bxw6jj5lmz48knrza8gq7sqywky247xpqccv2";
    }
  }/overlay.nix";
in {
  nixpkgs.overlays = [waylandOverlay];
  programs.obs-studio = {enable = true;};
  # ...
}
