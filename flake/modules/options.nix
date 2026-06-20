{ lib, ... }: {
  options.aliyss = {
    profiles = {
      llm = lib.mkEnableOption "LLM tools (ollama, llama-cpp, neo4j)";
      creative = lib.mkEnableOption "Creative apps (Affinity, Blender, DaVinci Resolve)";
      gaming = lib.mkEnableOption "Gaming (Steam, Heroic, Lutris, Bottles, Minecraft)";
      audio = lib.mkEnableOption "Audio tools (Carla, VMPK, vocoder)";
    };
    standaloneApps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Apps installed individually without enabling the full profile";
    };
  };
}
