{ pkgs, ... }: {
  nixpkgs.config.packageOverrides = pkg: {
    barracudavpn = pkgs.callPackage ../../../build/barracudavpn/default.nix {};
  };

  environment.systemPackages = with pkgs; [
    barracudavpn
    openrgb-with-all-plugins
  ];
}
