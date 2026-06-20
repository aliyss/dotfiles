{pkgs, ...}: let
  qwen2-7b-model = pkgs.fetchurl {
    name = "qwen2.5-coder-7b-instruct-q5_k_m.gguf";
    url = "https://huggingface.co";
    sha256 = "sha256-WGhE6sTW1jIWifAZLIqo5pzYYll0pcwtklsaAzZuTRY=";
  };

  llama-cpp-cuda = pkgs.llama-cpp.override {
    cudaSupport = true;
  };
in {
  # nixpkgs.config.allowUnfree = true;

  services.llama-swap = {
    enable = true;
    port = 8012;
    openFirewall = true;

    settings = {
      host = "0.0.0.0";
      default_ttl = 600;
      models = {
        "qwen2.5-7b" = {
          # Fully GPU accelerated
          cmd = "${pkgs.lib.getExe' llama-cpp-cuda "llama-server"} -m ${qwen2-7b-model} --port \${PORT} --n-gpu-layers 99 --flash-attn auto --ctx-size 16384 -b 512 -ub 512";

          # cmd = "${pkgs.lib.getExe' llama-cpp-cuda "llama-server"} -m ${qwen-coder-model} --port \${PORT} --n-gpu-layers 24 --flash-attn auto --ctx-size 16384 -b 512 -ub 512 --cache-type-k q8_0 --cache-type-v q8_0";
        };
        # "qwen2.5-14b" = {
        #   # Partially offloaded (adjust layers until it fits just under your VRAM limit)
        #   # If 14B requires more VRAM than you have, lower this number until it's stable
        #   cmd = "${pkgs.lib.getExe' llama-cpp-cuda "llama-server"} -m ${qwen2-14b-path} --port \${PORT} --n-gpu-layers 40 --flash-attn auto --ctx-size 8192 -b 512 -ub 512";
        # };
      };
    };
  };
}
