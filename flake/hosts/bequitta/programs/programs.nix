{pkgs, ...}: {
  nixpkgs.config.packageOverrides = pkg: {
    barracudavpn = pkgs.callPackage ../../../build/barracudavpn/default.nix {};
  };

  environment.systemPackages = with pkgs; [
    barracudavpn
    davinci-resolve
    blender

    openrgb-with-all-plugins
    (heroic.override {
      extraPkgs = pkgs: [
        pkgs.gamescope
      ];
    })
    mangohud
    lutris
    bottles
    protonup-qt
  ];
}
