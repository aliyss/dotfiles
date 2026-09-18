{ inputs, ... }: {
  nixpkgs.config.allowUnfree = true;
  # cudaSupport is host-specific: bequitta (NVIDIA) enables it, blisspla/blade (Intel) use false for cache hits
  nixpkgs.config.cudaSupport = false;
  nixpkgs.config.permittedInsecurePackages = [
    "qtwebengine-5.15.19"
  ];

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      extra-substituters = [
        "https://cache.forall.systems"
        "https://hyprland.cachix.org"
      ];
      extra-trusted-public-keys = [
        "cache.forall.systems:5PmD7QO4MSF8YgyRZtkSGXRDo96H3bybIf2SsQh8ScI="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };
    registry.nixpkgs.flake = inputs.nixpkgs;
    nixPath = ["nixpkgs=${inputs.nixpkgs}"];
  };
}
