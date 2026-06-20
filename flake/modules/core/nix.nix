{ inputs, ... }: {
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.cudaSupport = true;
  nixpkgs.config.permittedInsecurePackages = [
    "qtwebengine-5.15.19"
  ];

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      substituters = ["https://hyprland.cachix.org"];
      trusted-substituters = ["https://hyprland.cachix.org"];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    };
    registry.nixpkgs.flake = inputs.nixpkgs;
    nixPath = ["nixpkgs=${inputs.nixpkgs}"];
  };
}
