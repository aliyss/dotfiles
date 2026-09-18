{
  description = "Aliyss' flake.nix configuration file!";

  nixConfig = {
    extra-substituters = [
      "https://cache.forall.systems"
      "https://hyprland.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.forall.systems:5PmD7QO4MSF8YgyRZtkSGXRDo96H3bybIf2SsQh8ScI="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # playit-nixos-module.url = "github:pedorich-n/playit-nixos-module";
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
    forticlient-nixos.url = "github:jplana/forticlient-nixos";
    # Cisco AnyConnect with Azure AD / SAML MFA over NetworkManager+openconnect
    # (vpn-connect / vpn-disconnect); wired up in modules/core/networking.nix.
    # nixpkgs follows so the module evaluates against the host pkgs — it only
    # ships a .nix file and builds nothing from its own input.
    anyconnect-webauth = {
      url = "github:z10n-dev/nixos-anyconnect-webauth";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Android APK packages (used on the Termux phone): thousands of apps pinned
    # by app-id, e.g. `nix build .#com-darkempire78-opencalculator`.
    aliyss-android-pkgs.url = "github:aliyss/aliyss-android-pkgs";
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
    davinciOverlay = import ./overlays/davinci-resolve.nix;
    pkgs = import nixpkgs {
      localSystem = {inherit system;};
      config.allowUnfree = true;
      config.cudaSupport = false;
      overlays = [
        affinity-nix.overlays.default
        nur.overlays.default
        davinciOverlay
      ];
    };

    # Termux phone (Android, aarch64): Nix runs inside the existing Termux app
    # via chroot. Keep this pkgs minimal — only the phone home-manager config uses it.
    phoneSystem = "aarch64-linux";
    pkgsPhone = import nixpkgs {
      localSystem = {system = phoneSystem;};
      config.allowUnfree = true;
    };

    androidPkgs = inputs.aliyss-android-pkgs;

    lib = nixpkgs.lib;

    # Vulkan device smoke check helper for blisspla is added to the host profile
    # via the blisspla NixOS config's profile module. No flakeside export needed.

    sharedConfigurationModules = [
      ./modules/default.nix
      home-manager.nixosModules.home-manager
    ];
  in {
    # Android APK packages from aliyss-android-pkgs, re-exported so they can be
    # built directly from this flake on any supported system (e.g. the phone).
    packages = {
      ${system} = androidPkgs.packages.${system};
      ${phoneSystem} = androidPkgs.packages.${phoneSystem};
    };

    # NixOS configurations
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
            ./hosts/blisspla/hardware-configuration.nix
            ./hosts/blisspla/configuration.nix
            ./hosts/blisspla/services/llama-vulkan-devices-profile.nix
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
      # Aliyss' phone (Termux on Android, Nix via chroot). Activated on-device by
      # aliyss-phone/update-phone.sh after aliyss-phone/nix-install.sh bootstrapped Nix.
      aliyss-termux = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsPhone;
        modules = [
          ./hosts/termux/home.nix
        ];
        extraSpecialArgs = inputs;
      };
    };
  };
}
