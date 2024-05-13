{...}: let
  rev = "master"; # 'rev' could be a git rev, to pin the overlay.
  url = "https://github.com/nix-community/nixpkgs-wayland/archive/${rev}.tar.gz";
  waylandOverlay = import "${
    builtins.fetchTarball {
      url = url;
      sha256 = "0k65alg6i96z0vxahmd0fanjlc0vnnv9zc3y479q9rvd2bb13g35";
    }
  }/overlay.nix";
in {
  nixpkgs.overlays = [waylandOverlay];
  programs.obs-studio = {enable = true;};
  # ...
}
