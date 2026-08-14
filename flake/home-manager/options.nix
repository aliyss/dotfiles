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
  };
}
