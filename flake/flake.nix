{
  description = "Aliyss' flake.nix configuration file!";

  inputs = {
    zen-browser.url = "github:MarceColl/zen-browser-flake";
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
    prismlauncher.url = "github:julcioo/PrismLauncher-Cracked";
    nur.url = "github:nix-community/nur";
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
    };

    lib = nixpkgs.lib;
  in {
    # NIXOS CONFIGURATIONS
    nixosConfigurations = {
      # Desktop
      aliyss-bequitta = lib.nixosSystem {
        specialArgs = {
          inherit system;
          inherit inputs;
        };
        modules = [
          ./configuration.nix
          ./bequitta/configuration.nix
          home-manager.nixosModules.home-manager
        ];
      };
      # Laptop: Not yet merged
      aliyss-blade = lib.nixosSystem {
        specialArgs = {
          inherit system;
          inherit inputs;
        };
        modules = [./configuration.nix];
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
