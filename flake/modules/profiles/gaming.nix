{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.aliyss.profiles;
  standalone = config.aliyss.standaloneApps;
  hasGaming = cfg.gaming || elem "gaming" standalone;
  hasHeroic = cfg.gaming || elem "heroic" standalone;
  hasSteam = cfg.gaming || elem "steam" standalone;
in mkIf (hasGaming || hasHeroic || hasSteam) {
  programs.steam.enable = hasSteam;
  programs.gamescope.enable = hasSteam || hasHeroic;
  programs.gamemode.enable = hasGaming;
}
