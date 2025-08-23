{
  description = "Aliyss' flake.nix configuration file!";

  inputs = {
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
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
  };

  outputs = {
    nixpkgs,
    nur,
    home-manager,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      localSystem = {inherit system;};
      config.allowUnfree = true;
      overlays = [nur.overlays.default];
    };

    lib = nixpkgs.lib;

    sharedConfigurationModules = [
      ./configuration.nix
      ./shared/configuration.nix
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
    };
    # HOME CONFIGURATIONS
    homeConfigurations = {
      # Aliyss' User Profile
      aliyss = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [./home-manager/home.nix];
        extraSpecialArgs = inputs;
      };
    };
  };
}
