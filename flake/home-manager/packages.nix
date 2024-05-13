{pkgs, ...}: let
  minecraftServerInfo = {
    version = "1.20.2";
    url = "https://launcher.mojang.com/v1/objects/5b868151bd02b41319f54c8d4061b8cae84e665c/server.jar";
    sha256 = "sha256-Ha7kg4VprUbkHwpvRZaExQDH8mhTVqQM+36DjW546ug=";
  };
in {
  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
    atool
    httpie
    tmux
    stremio
    tridactyl-native
    prismlauncher
    nyxt

    (pkgs.minecraftServers.vanilla-1-20.overrideAttrs (old: rec {
      name = "minecraft-server-${minecraftServerInfo.version}";
      version = minecraftServerInfo.version;
      src = pkgs.fetchurl {
        url = minecraftServerInfo.url;
        sha256 = minecraftServerInfo.sha256;
      };
    }))
    # ngrok
    btop

    (pkgs.callPackage ./apps/zrok.nix {})
  ];
}
