{lib, ...}: {
  options.aliyss = {
    profiles = {
      llm = lib.mkEnableOption "LLM tools";
      creative = lib.mkEnableOption "Creative apps (Affinity)";
      gaming = lib.mkEnableOption "Gaming (Minecraft, PrismLauncher)";
      audio = lib.mkEnableOption "Audio tools";
    };
    standaloneApps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Apps installed individually without enabling the full profile";
    };
  };
}
