{pkgs, ...}: {
  # The home.packages option allows you to install Nix packages into your
  # environment.
  packages = with pkgs; [
    slack
    bruno
    dbeaver-bin
  ];
}
