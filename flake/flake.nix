{
  description = "Aliyss' flake.nix configuration file!";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    playit-nixos-module.url = "github:pedorich-n/playit-nixos-module";
    prismlauncher.url = "github:Diegiwg/PrismLauncher-Cracked";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tridactyl-native-messenger = {
      url = "github:tridactyl/native_messenger";
      flake = false;
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    hyprland-dynamic-cursors = {
      url = "github:VirtCode/hypr-dynamic-cursors";
      inputs.hyprland.follows = "hyprland";
    };
    affinity-nix.url = "github:mrshmllow/affinity-nix";
    tidalcycles-nix = {
      url = "github:DivitMittal/tidalcycles-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    herdr = {
      url = "github:ogulcancelik/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    nur,
    home-manager,
    tidalcycles-nix,
    affinity-nix,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      localSystem = {inherit system;};
      config.allowUnfree = true;
      overlays = [
        affinity-nix.overlays.default
        nur.overlays.default
      ];
    };

    lib = nixpkgs.lib;

    sharedConfigurationModules = [
      ./modules/default.nix
      home-manager.nixosModules.home-manager
    ];
  in {
    # NIXOS CONFIGURATIONS
    nixosConfigurations = {
      # Desktop
      aliyss-bequitta = lib.nixosSystem {
        specialArgs = {
          inherit system;
          inherit inputs;
        };
        modules =
          [
            ./hosts/bequitta/hardware-configuration.nix
            ./hosts/bequitta/configuration.nix
          ]
          ++ sharedConfigurationModules;
      };
      # Laptop: Not yet merged
      aliyss-blade = lib.nixosSystem {
        specialArgs = {
          inherit system;
          inherit inputs;
        };
        modules =
          [
            ./hosts/blade/hardware-configuration.nix
            ./hosts/blade/configuration.nix
          ]
          ++ sharedConfigurationModules;
      };
      # Desktop
      aliyss-blisspla = lib.nixosSystem {
        specialArgs = {
          inherit system;
          inherit inputs;
        };
        modules =
          [
            # ./hosts/blisspla/hardware-configuration.nix
            ./hosts/blisspla/configuration.nix
          ]
          ++ sharedConfigurationModules;
      };
    };
    # FORMATTER
    formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt;

    # HOME CONFIGURATIONS
    homeConfigurations = {
      # Aliyss' User Profile
      aliyss = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home-manager/home.nix
        ];
        extraSpecialArgs = inputs;
      };
    };
  };
}
