{ pkgs, inputs, lib, ... }: {
  imports = [
    ./options.nix

    ./core/boot.nix
    ./core/networking.nix
    ./core/locale.nix
    ./core/nix.nix
    ./core/env.nix

    ./hardware/nvidia.nix
    ./hardware/bluetooth.nix
    ./hardware/fonts.nix

    ./services/pipewire.nix
    ./services/docker.nix
    ./services/greetd.nix
    ./services/display-manager.nix
    ./services/waydroid.nix
    ./services/keyd.nix
    ./services/xdg-portal.nix
    ./services/misc.nix

    ./programs/hyprland.nix
    ./programs/hyprlock.nix
    ./programs/zoxide.nix
    ./programs/fish.nix
    ./programs/gnupg.nix
    ./programs/nix-ld.nix

    ./users/aliyss.nix

    ./packages/system.nix

    ./profiles/llm.nix
    ./profiles/creative.nix
    ./profiles/gaming.nix
    ./profiles/audio.nix
    ../local.nix
  ];

  system.stateVersion = "23.05";
}
