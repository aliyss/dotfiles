{ lib, ... }: {
  options.aliyss = {
    isPhone = lib.mkEnableOption ''
      Termux phone target (Android, Nix via chroot). Gate for phone-specific
      behavior: real-file configs (native Termux can't see the Nix store),
      Tailscale/sshd handling, no Hyprland.
    '';
    profiles = {
      llm = lib.mkEnableOption "LLM tools";
      creative = lib.mkEnableOption "Creative apps (Affinity)";
      gaming = lib.mkEnableOption "Gaming (Minecraft, PrismLauncher)";
      audio = lib.mkEnableOption "Audio tools";
    };
    standaloneApps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Apps installed individually without enabling the full profile";
    };
    adobeFonts = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Adobe Fonts (Typekit) Auto Pro extractor – also syncs to Wine for Affinity";
      };
      kitId = lib.mkOption {
        type = lib.types.str;
        default = "whl2slc";
        description = "Adobe Fonts kit ID";
      };
    };
    tailscaleSocks5Port = lib.mkOption {
      type = lib.types.str;
      default = "23008";
      description = ''
        Port of the phone's tailscaled SOCKS5 proxy (userspace-networking
        mode), set by apps/tailscale.nix on the daemon's --socks5-server flag.
      '';
    };
  };
}
