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
    adobeFonts = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Adobe Fonts (Typekit) Auto Pro extractor – fetches kit whl2slc and installs via fontconfig + Wine for Affinity";
      };
      kitId = lib.mkOption {
        type = lib.types.str;
        default = "whl2slc";
        description = "Adobe Fonts kit ID from https://use.typekit.net/<kitId>.css";
      };
    };
  };
}
