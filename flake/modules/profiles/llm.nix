{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.aliyss.profiles;
  # Host-specific acceleration: bequitta (NVIDIA) → CUDA, blisspla/blade (Intel Arc) → Vulkan
  # Single source of truth for both — same API (127.0.0.1:8012, same models) but optimal backend per host.
  isCudaHost = config.networking.hostName == "aliyss-bequitta";
  isVulkanHost = !isCudaHost;

  llamaCuda = pkgs.llama-cpp.override {
    cudaSupport = true;
    vulkanSupport = false;
    rocmSupport = false;
  };

  llamaVulkan = pkgs.llama-cpp.override {
    vulkanSupport = true;
    cudaSupport = false;
  };

  llamaPackage = if isCudaHost then llamaCuda else llamaVulkan;

  mesaIntelIcdPath = "${pkgs.mesa}/share/vulkan/icd.d/intel_icd.x86_64.json";

  # Vulkan smoke check helper — only meaningful on Vulkan hosts, but package is built against the Vulkan build
  llamaVulkanDevices = pkgs.writeShellScriptBin "llama-vulkan-devices" (pkgs.runCommand "llama-vulkan-devices.sh" {
      nativeBuildInputs = [pkgs.coreutils pkgs.jq];
      llamaServer = pkgs.lib.getExe' llamaVulkan "llama-server";
      mesaIntelIcdPath = mesaIntelIcdPath;
    } ''
      install -m 0755 "$llamaServer" $out/bin/llama-server-real
      mesa_icd="${mesaIntelIcdPath}"
      cat > $out/bin/llama-vulkan-devices <<'EOF'
      #!/usr/bin/env bash
      set -euo pipefail

      server="$(dirname "$0")/llama-server-real"
      if [ ! -x "$server" ]; then
        echo "llama-vulkan-devices: llama-server-real missing — rebuild this package" >&2
        exit 1
      fi

      tmpcache="$(mktemp -d)"
      trap 'rm -rf "$tmpcache"' EXIT
      export XDG_CACHE_HOME="$tmpcache"
      export MESA_SHADER_CACHE_DIR="$tmpcache"

      raw="$("$server" --list-devices 2>&1)" || {
        echo "llama-vulkan-devices: llama-server --list-devices exited non-zero" >&2
        echo "$raw" >&2
        exit 1
      }

      intel=0
      llvmpipe=0
      softpipe=0

      while IFS= read -r line; do
        case "$line" in
          *Intel*|*intel_icd*|*ANV*|*Intel(R)*)
            intel=$((intel + 1))
            ;;
          *llvmpipe*|*LLVMpipe*|*llvmpipe (LLVM)*)
            llvmpipe=$((llvmpipe + 1))
            ;;
          *softpipe*|*Software Pipe*)
            softpipe=$((softpipe + 1))
            ;;
        esac
      done <<< "$raw"

      echo "devices"
      echo "  raw output:"
      echo "$(echo "$raw" | sed 's/^/    /' || true)"
      echo
      echo "decision:"
      echo "  intel-icd-like lines: $intel"
      echo "  llvmpipe-like lines: $llvmpipe"
      echo "  softpipe-like lines: $softpipe"
      echo

      if [ "$intel" -gt 0 ] && [ "$llvmpipe" -eq 0 ] && [ "$softpipe" -eq 0 ]; then
        echo "OK: Intel ICD device visible, no llvmpipe/softpipe in the enumerated set."
        exit 0
      fi

      echo "FAIL: expected at least one Intel ICD device and no llvmpipe/softpipe." >&2
      if [ "$intel" -eq 0 ]; then
        echo "  -> no Intel ICD device seen in the Vulkan build's device list." >&2
      fi
      if [ "$llvmpipe" -gt 0 ] || [ "$softpipe" -gt 0 ]; then
        echo "  -> a software Vulkan ICD (llvmpipe/softpipe) is present in the set." >&2
      fi
      echo
      echo "Fix direction:" >&2
      echo "  VK_DRIVER_FILES=\"$mesa_icd\"" >&2
      exit 1
      EOF
    '');

  # Shared models-preset — identical on both hosts so agents see the same model ids / sampling
  modelsPreset = (pkgs.formats.ini {}).generate "llama-cpp-models.ini" {
    "qwen3.5-9b" = {
      hf-repo = "unsloth/Qwen3.5-9B-MTP-GGUF";
      hf-file = "Qwen3.5-9B-UD-Q4_K_XL.gguf";
      alias = "qwen3.5-9b";
      ctx-size = "65536";
      parallel = "1";
      spec-type = "draft-mtp";
      spec-draft-n-max = "6";
      temp = "0.7";
      top-p = "0.8";
      top-k = "20";
      min-p = "0.0";
    };

    "qwen3.5-4b" = {
      hf-repo = "mradermacher/Qwen3.5-4B-abliterated-i1-GGUF";
      hf-file = "Qwen3.5-4B-abliterated.i1-Q4_K_M.gguf";
      alias = "qwen3.5-4b,default";
      ctx-size = "32768";
      parallel = "1";
      temp = "0.7";
      top-p = "0.8";
      top-k = "20";
      min-p = "0.0";
    };

    "gpt-oss-20b" = {
      hf-repo = "ggml-org/gpt-oss-20b-GGUF";
      hf-file = "gpt-oss-20b-MXFP4.gguf";
      alias = "gpt-oss-20b";
      ctx-size = "32768";
      temp = "1.0";
      top-p = "1.0";
      top-k = "0";
      min-p = "0.0";
    };
  };
in
  mkIf cfg.llm {
    # Unified local LLM — same endpoint on every host, hardware-optimal backend per host
    # bequitta: CUDA (nvidia) — full VRAM offload, fastest for 9B/20B
    # blisspla/blade: Vulkan (Intel Arc via Mesa/ANV) — only needs Mesa ICD
    services.llama-cpp = {
      enable = true;
      package = llamaPackage;
      openFirewall = false;
      settings = {
        host = "127.0.0.1";
        port = 8012;

        models-preset = modelsPreset;
        models-max = 1;

        # All layers on GPU — CUDA on bequitta, Vulkan on blisspla
        n-gpu-layers = 99;
        flash-attn = "on";
        no-mmproj = true;
        jinja = true;
      };
    };

    systemd.services.llama-cpp = {
      environment = {
        XDG_CACHE_HOME = "/var/cache/llama-cpp";
        MESA_SHADER_CACHE_DIR = "/var/cache/llama-cpp";
      } // optionalAttrs isVulkanHost {
        GGML_VK_VISIBLE_DEVICES = "0";
      };
      serviceConfig = mkMerge [
        {
          # Ensure cache dir exists for DynamicUser (both hosts)
          CacheDirectory = "llama-cpp";
          CacheDirectoryMode = "0755";
        }
        (mkIf isVulkanHost {
          Environment = [
            "VK_DRIVER_FILES=${mesaIntelIcdPath}"
          ];
        })
      ];
    };

    # Expose the package and Vulkan helper — helper only on Vulkan hosts, package on both
    environment.systemPackages = [llamaPackage] ++ optionals isVulkanHost [llamaVulkanDevices];
  }
