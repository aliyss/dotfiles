{
  pkgs,
  audio-plugins,
  nixpkgs-for-stremio,
  affinity-nix,
  prismlauncher,
  tidalcycles,
  ...
}: let
  work-packages = import ./work-packages.nix {inherit pkgs;};
  broken-packages = import ./broken-packages.nix {inherit pkgs;};
  minecraftServerInfo = {
    version = "1.21";
    url = "https://piston-data.mojang.com/v1/objects/450698d1863ab5180c25d7c804ef0fe6369dd1ba/server.jar";
    sha256 = "sha256-yWOU2ob52fnvfKLS7h8vCYDCm3qlyUtDwCxQQ1289T8=";
  };
  tidalcycles-packages = import pkgs.path {
    inherit (pkgs) system;
    overlays = [tidalcycles.overlays.default];
  };
in {
  imports = [];

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = let
    stremioPkgs = import nixpkgs-for-stremio {
      inherit (pkgs) system;
    };
  in
    with pkgs;
      [
        # # You can also create simple shell scripts directly inside your
        # # configuration. For example, this adds a command 'my-hello' to your
        # # environment:
        # (pkgs.writeShellScriptBin "my-hello" ''
        #   echo "Hello, ${config.home.username}!"
        # '')

        # ---------------------------------- #
        # Isaac Sekei
        # ---------------------------------- #

        ## Development
        bun
        jq
        ripgrep
        fd
        gh

        ## Terminal
        opencode

        # ---------------------------------- #
        # Yara Seraci
        # ---------------------------------- #

        ## Movies / Series / Anime
        # (stremioPkgs.stremio)
        stremio-linux-shell
        ani-cli

        ## Social
        gurk-rs

        ## Gaming
        prismlauncher.packages.${stdenv.hostPlatform.system}.default
        (pkgs.minecraft-server.overrideAttrs (old: {
          name = "minecraft-server-${minecraftServerInfo.version}";
          version = minecraftServerInfo.version;
          src = pkgs.fetchurl {
            url = minecraftServerInfo.url;
            sha256 = minecraftServerInfo.sha256;
          };
        }))

        ## Music
        pear-desktop

        # ---------------------------------- #
        # Lowe Söderberg
        # ---------------------------------- #

        ## Secret Management
        bitwarden-cli
        rbw # Rust Bitwarden CLI - Faster than bitwarden-cli and uses memory storage

        ## Email
        mutt-wizard
        neomutt
        pass
        notmuch
        abook
        cronie
        isync
        himalaya
        mhonarc

        # ---------------------------------- #
        # Other
        # ---------------------------------- #

        ## Images
        libsixel
        blender
        affinity-nix.packages.${pkgs.stdenv.hostPlatform.system}.v3

        ## Terminal
        sshpass
        httpie
        tmux

        ## Browser
        tridactyl-native
        chawan
        chromium
        google-chrome

        ## Monitoring
        btop

        ## Utilities
        yarn-berry
        qbittorrent

        # ---------------------------------- #
        # Deprecated / Unused
        # ---------------------------------- #
        # atool
        davinci-resolve

        # Music
        (haskellPackages.ghcWithPackages (p: [p.tidal]))
        supercollider-with-sc3-plugins
      ]
      ++ work-packages.packages
      ++ broken-packages.packages;
}
