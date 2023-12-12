{ config, pkgs, ... }:

{
  services.minecraft-server = {
    enable = true;
    eula = true;
    package = pkgs."minecraft-server";
    openFirewall = true;
    declarative = true;
    # see here for more info: https://minecraft.gamepedia.com/Server.properties#server.properties
    serverProperties = {
      server-port = 25565;
      gamemode = "survival";
      motd = "NixOS Minecraft server";
      max-players = 5;
      enable-rcon = true;
      enable-query = true;
      # This password can be used to administer your minecraft server.
      # Exact details as to how will be explained later. If you want
      # you can replace this with another password.
      # rcon.password = "hunter2";
      # query.port = 25565;
    };
  };
  nixpkgs.config.allowUnfree = true;
}
