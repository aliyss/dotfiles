{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.aliyss.profiles;
  standalone = config.aliyss.standaloneApps;
in mkIf (cfg.creative || elem "obs" standalone) {
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-backgroundremoval
      obs-pipewire-audio-capture
    ];
  };
}
