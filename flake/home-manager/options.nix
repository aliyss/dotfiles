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
    tailscaleSocks5Port = lib.mkOption {
      type = lib.types.str;
      default = "23008";
      description = ''
        Port of the phone's tailscaled SOCKS5 proxy (userspace-networking
        mode). Single source of truth: consumed by apps/tailscale.nix (the
        runit service args) and apps/fish.nix (the ssh aliases that route
        through the proxy via connect(1)).
      '';
    };
  };
}
