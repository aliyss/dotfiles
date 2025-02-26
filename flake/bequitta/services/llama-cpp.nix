{pkgs, ...}: let
  deepseek-coder = pkgs.fetchurl {
    name = "sakura-14b-qwen2.5-v1.0-q6k.gguf";
    url = "https://huggingface.co/TheBloke/deepseek-coder-6.7B-instruct-GGUF/blob/main/deepseek-coder-6.7b-instruct.Q2_K.gguf?download=true";
    sha256 = "sha256-2vGe2Ip5DIqKIkCp1Zw63+PluhpASjazX+vslV+FM3o=";
  };
in {
  services.llama-cpp = {
    enable = true;
    port = 8012;
    host = "0.0.0.0";
    package = pkgs.llama-cpp.override {
      cudaSupport = true;
    };
    model = "/home/aliyss/Downloads/deepseek-coder-6.7b-instruct.Q2_K.gguf";
  };
  # services.open-webui = {
  #   enable = true;
  #   openFirewall = true;
  #   port = 8082;
  #   host = "0.0.0.0";
  #   environment = {
  #     OLLAMA_API_BASE_URL = "http://127.0.0.1:8012";
  #     # Disable authentication
  #     # WEBUI_AUTH = "False";
  #     ANONYMIZED_TELEMETRY = "False";
  #     DO_NOT_TRACK = "True";
  #     SCARF_NO_ANALYTICS = "True";
  #   };
  # };
}
