{
  pkgs,
  spicetify-nix,
  ...
}: let
  work-packages = import ./work-packages.nix {inherit pkgs;};
  broken-packages = import ./broken-packages.nix {inherit pkgs;};
  minecraftServerInfo = {
    version = "1.21";
    url = "https://piston-data.mojang.com/v1/objects/450698d1863ab5180c25d7c804ef0fe6369dd1ba/server.jar";
    sha256 = "sha256-yWOU2ob52fnvfKLS7h8vCYDCm3qlyUtDwCxQQ1289T8=";
  };
in {
  imports = [spicetify-nix.homeManagerModules.default];
  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs;
    [
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
      # heroic
      # nyxt
      bun
      jq
      lynx

      (pkgs.minecraft-server.overrideAttrs (old: {
        name = "minecraft-server-${minecraftServerInfo.version}";
        version = minecraftServerInfo.version;
        src = pkgs.fetchurl {
          url = minecraftServerInfo.url;
          sha256 = minecraftServerInfo.sha256;
        };
      }))

      btop

      aw-server-rust

      speedtest-cli

      ## Email
      mutt-wizard
      neomutt
      pass
      lynx
      notmuch
      abook
      cronie
      isync

      ## Himalaya
      himalaya
      chawan
      libsixel
    ]
    ++ work-packages.packages
    ++ broken-packages.packages;
}
