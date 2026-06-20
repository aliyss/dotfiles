{ pkgs, prismlauncher, ... }:
let
  minecraftServerInfo = {
    version = "1.21";
    url = "https://piston-data.mojang.com/v1/objects/450698d1863ab5180c25d7c804ef0fe6369dd1ba/server.jar";
    sha256 = "sha256-yWOU2ob52fnvfKLS7h8vCYDCm3qlyUtDwCxQQ1289T8=";
  };
in with pkgs; [
  prismlauncher.packages.${pkgs.stdenv.hostPlatform.system}.default
  (minecraft-server.overrideAttrs (old: {
    name = "minecraft-server-${minecraftServerInfo.version}";
    version = minecraftServerInfo.version;
    src = fetchurl {
      url = minecraftServerInfo.url;
      sha256 = minecraftServerInfo.sha256;
    };
  }))
]
