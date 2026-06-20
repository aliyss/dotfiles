{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.aliyss.profiles;
in
  mkIf cfg.llm {
    nixpkgs.config.cudaSupport = true;

    # services.ollama = {
    #   enable = true;
    #   package = pkgs.ollama-cuda;
    # };

    services.llama-swap = {
      enable = true;
      port = 8012;
      openFirewall = true;
      settings = {
        host = "0.0.0.0";
        default_ttl = 600;
        models = {
          "qwen2.5-7b" = {
            cmd = ''
              ${pkgs.lib.getExe' (pkgs.llama-cpp.override {cudaSupport = true;}) "llama-server"} \
                -m ${pkgs.fetchurl {
                name = "qwen2.5-coder-7b-instruct-q5_k_m.gguf";
                url = "https://huggingface.co";
                sha256 = "sha256-WGhE6sTW1jIWifAZLIqo5pzYYll0pcwtklsaAzZuTRY=";
              }} \
                --port ''${PORT} --n-gpu-layers 99 --flash-attn auto --ctx-size 16384 -b 512 -ub 512
            '';
          };
        };
      };
    };
  }
