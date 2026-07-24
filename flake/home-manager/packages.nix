{ config, lib, pkgs, prismlauncher, ... }:
with lib;
let
  cfg = config.aliyss.profiles;
  standalone = config.aliyss.standaloneApps;
  isaac = import ./packages/isaac.nix { inherit pkgs; };
  yara = import ./packages/yara.nix { inherit pkgs; };
  lowe = import ./packages/lowe.nix { inherit pkgs; };
  work = import ./packages/work.nix { inherit pkgs; };
  other = with pkgs; [
    libsixel
    sshpass
    httpie
    tridactyl-native
    chawan
    chromium
    sshfs-fuse
    google-chrome
    btop
    yarn-berry
    qbittorrent
  ];
in {
  home.packages =
    isaac
    ++ yara
    ++ lowe
    ++ work
    ++ other
    # Creative
    ++ optionals (cfg.creative || elem "affinity" standalone) (with pkgs; [ affinity-v3 ])
    ++ optionals (cfg.creative || elem "blender" standalone) (with pkgs; [ blender ])
    ++ optionals (cfg.creative || elem "davinci" standalone) (with pkgs; [ davinci-resolve ])
    # Gaming - individual
    ++ optionals (cfg.gaming || elem "heroic" standalone) (with pkgs; [
      (heroic.override { extraPkgs = pkgs: [pkgs.gamescope]; })
    ])
    # Gaming - full suite
    ++ optionals (cfg.gaming || elem "gaming" standalone) (import ./packages/gaming.nix {
      inherit pkgs prismlauncher;
    })
    ++ optionals (cfg.gaming || elem "gaming" standalone) (with pkgs; [
      mangohud lutris bottles protonup-qt
      wineWow64Packages.staging winetricks wineWow64Packages.waylandFull
    ])
    # Audio
    ++ optionals cfg.audio (with pkgs; [
      (distrho-ports.override {plugins = ["tal-vocoder-2"];})
      carla vmpk
    ]);
}
