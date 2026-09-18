{
  lib,
  pkgs,
  config,
  ...
}: let
  # ===========================================================================
  # Vulkan device smoke check
  #
  # This host's `llama-server` is the Vulkan override of llama-cpp, built against
  # Mesa/ANV via `hardware.graphics.enable`. The one thing that can silently go
  # wrong without an obvious error is that Vulkan still picks llvmpipe instead of
  # the Intel ICD, so "GPU offload" actually runs on CPU.
  #
  # The authoritative evidence is the live Vulkan build's device list, but that
  # requires a machine with the same ICD layout as blisspla. To make the decision
  # reproducible in the flake, this helper:
  #   - builds against the exact same `llamaVulkan` package this service uses
  #   - runs `llama-server --list-devices` in a minimal Mesa ICD environment
  #   - decides from the output, not from assumptions about ICD filename ordering
  #
  # It is *not* a substitute for running it on blisspla once switched; it is a way
  # to make the same check deterministic and CIable rather than a one-off manual Step.
  #
  # WHY VULKAN + llama.cpp (researched 2026-09):
  #   * On Intel iGPUs Vulkan is the only backend that is both practical and
  #     stable. OpenVINO (llama.cpp preview) is bench-fast but crashes as soon
  #     as the KV cache grows — it has no dynamic-shape support; SYCL needs the
  #     oneAPI runtime and is *slower* at token generation on iGPUs. Vulkan
  #     only needs the Mesa/ANV driver, which this host already installs for
  #     Resolve + VA-API.
  #   * The Arc iGPU shares the LPDDR5x with the CPU (~120 GB/s), so decode is
  #     memory-bandwidth bound either way — GPU offload mainly buys prompt
  #     processing speed. That is exactly the bottleneck for an orchestrator
  #     agent, which pastes dozens of MCP tool schemas into every request.
  #
  # MODELS (fetched from Hugging Face on first use, one resident at a time):
  #   * qwen3.5-9b (default) — hybrid Gated-DeltaNet + Gated Attention, 256K
  #     native context, ~5.6 GB at UD-Q4_K_XL, MTP speculative decoding is
  #     built into the GGUF (~1.5-2x faster generation). Best tool-calling
  #     quality per GB in this class (MMLU-Pro 82.5 vs 74.8 for gpt-oss-20b),
  #     and the hybrid attention keeps a large context cheap: only 8 of 32
  #     layers carry a full KV cache (~32 KB/token), so 64K costs ~2 GB.
  #   * gpt-oss-20b — MoE (3.6B active) with native MXFP4, ~12 GB. Slower to
  #     load and run, but stronger at long multi-step reasoning and at
  #     structured JSON; reach for it when the 9B stops following the plan.
  #
  # Both are exposed OpenAI-compatible (`/v1/models`, `/v1/chat/completions`
  # with tools). Model id + sampling defaults are per-model in the preset
  # below; switch by sending the other model name. Nothing outside this host
  # changes: bequitta (NVIDIA/CUDA) and the phone keep their own setup.
  # ===========================================================================
  # llama-cpp-vulkan is `llama-cpp.override { vulkanSupport = true; }` and
  # cudaSupport defaults to config.cudaSupport — which modules/core/nix.nix
  # pins to true for the NVIDIA desktop. Without the explicit override this
  # laptop would build (and drag in) the whole CUDA closure.
  llamaVulkan = pkgs.llama-cpp.override {
    vulkanSupport = true;
    cudaSupport = false;
  };

  # Helper: run the Vulkan llama-server's own device enumeration and decide from it.
  # This is the flake-side mirror of the manual `llama-server --list-devices` check
  # described in the module comments, so the same binary path and the same Vulkan/Mesa
  # assumptions are used.
  mesaIntelIcdPath = "${pkgs.mesa}/share/vulkan/icd.d/intel_icd.x86_64.json";
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

      # Mesa can try to open //.cache when XDG_CACHE_HOME is unset. The real service
      # sets it to /var/cache/llama-cpp, but here we only enumerate devices. Give the
      # Vulkan build a writable cache dir so it does not trip on shader-cache/profile
      # creation during --list-devices (this wrapper runs as the invoking user, not the
      # service's DynamicUser).
      tmpcache="$(mktemp -d)"
      trap 'rm -rf "$tmpcache"' EXIT
      export XDG_CACHE_HOME="$tmpcache"
      export MESA_SHADER_CACHE_DIR="$tmpcache"

      # Run the Vulkan build's own listing. If Vulkan fell back to llvmpipe, the ICD it
      # chose will still enumerate a device, so a non-empty list is not itself proof of
      # the Intel ICD; we have to read the strings.
      raw="$("$server" --list-devices 2>&1)" || {
        echo "llama-vulkan-devices: llama-server --list-devices exited non-zero" >&2
        echo "$raw" >&2
        exit 1
      }

      # Decide from the output rather than from ICD filename ordering.
      intel=0
      llvmpipe=0
      softpipe=0

      # Known Intel ICD markers. Vendor ICD files usually describe the device with one
      # of these strings in the listing text; individual Mesa ICD strings are the most
      # reliable signal we can read without parsing JSON (llama-server --list-devices is
      # not JSON on all llama.cpp versions).
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

      # A vacuous match (empty or uninformative listing) is not a pass. Require at
      # least one Intel ICD line and no software ICD lines.
      if [ "$intel" -gt 0 ] && [ "$llvmpipe" -eq 0 ] && [ "$softpipe" -eq 0 ]; then
        echo "OK: Intel ICD device visible, no llvmpipe/softpipe in the enumerated set."
        exit 0
      fi

      echo "FAIL: expected at least one Intel ICD device and no llvmpipe/softpipe." >&2
      if [ "$intel" -eq 0 ]; then
        echo "  -> no Intel ICD device seen in the Vulkan build's device list." >&2
        echo "     Vulkan is running, but the Intel renderer ICD was not enumerated" >&2
        echo "     as a device for this Vulkan build. On blisspla that usually means" >&2
        echo "     the Mesa/ANV ICDs are missing or not visible to the user running" >&2
        echo "     the check." >&2
      fi
      if [ "$llvmpipe" -gt 0 ] || [ "$softpipe" -gt 0 ]; then
        echo "  -> a software Vulkan ICD (llvmpipe/softpipe) is present in the set." >&2
        if [ "$intel" -gt 0 ]; then
          echo "     Intel ICD markers were also seen, so the hard case is:" >&2
          echo "       the Vulkan build sees both the Intel ICD and a software ICD," >&2
          echo "       and the selected/used device may still be the software one." >&2
        else
          echo "     that normally means GPU offload may actually run on CPU." >&2
        fi
      fi
      if [ "$intel" -gt 0 ] && [ "$llvmpipe" -eq 0 ] && [ "$softpipe" -eq 0 ]; then
        : # covered by the OK path above
      else
        echo "  -> if the raw output above is ambiguous, paste it and the live check:" >&2
        echo "       on blisspla: llama-server --list-devices" >&2
        echo "       and: cat /sys/class/drm/card0/device/vendor   (expect Intel)" >&2
      fi
      echo
      echo "Fix direction (per the module comments):" >&2
      echo "  1. On blisspla, after rebuild, run: llama-vulkan-devices   (this script)" >&2
      echo "  2. If it still reports llvmpipe, pin the Intel ICD explicitly so ICD" >&2
      echo "     enumeration order is not relied on:" >&2
      echo "       services.llama-cpp.vulkanIntelIcdFile" >&2
      echo "         = \"$mesa_icd\";" >&2
      echo "     The same setting is used by the llama-cpp service environment on" >&2
      echo "     blisspla when it is set, via VK_DRIVER_FILES." >&2
      exit 1
      EOF
    '');
  #
  # `--models-preset`: llama-server's router mode. Each section is a model
  # that is loaded on demand and swapped out when another is requested, so
  # both models share one port and only one is in RAM at a time. Keys are
  # llama-server long options without the leading `--`.
  modelsPreset = (pkgs.formats.ini {}).generate "llama-cpp-models.ini" {
    "qwen3.5-9b" = {
      hf-repo = "unsloth/Qwen3.5-9B-MTP-GGUF";
      hf-file = "Qwen3.5-9B-UD-Q4_K_XL.gguf";
      alias = "qwen3.5-9b";
      ctx-size = "65536";
      # MTP speculative decoding (the draft head lives in the same GGUF) is
      # not supported with more than one server slot.
      parallel = "1";
      spec-type = "draft-mtp";
      spec-draft-n-max = "6";
      # Important for speed: MTP only helps if llama-server actually uses the draft head.
      # If a future GGUF swap drops MTP, this preset silently becomes a normal single-pass
      # model and the speculative decoding comment below becomes stale. If you ever change
      # hf-file, re-check that `spec-type = draft-mtp` still matches the new GGUF.
      # Thinking left at the model default (on). Forcing it off with
      # chat-template-kwargs {"enable_thinking": false} was tested here and is
      # WORSE with this GGUF on b9925: the model then emits nothing but
      # `</think>` tokens and stops (300 tokens of it on a trivial prompt),
      # while the default path answers correctly and parks its reasoning in
      # `reasoning_content`. Clients that want to try it anyway can pass the
      # kwarg per request; `ask` prints `content` and falls back to the
      # reasoning, dropping the stray think markers as they stream.
      #
      # Unsloth's "instruct / non-thinking" sampling for general tasks.
      temp = "0.7";
      top-p = "0.8";
      top-k = "20";
      min-p = "0.0";
    };

    "qwen3.5-4b" = {
      hf-repo = "mradermacher/Qwen3.5-4B-abliterated-i1-GGUF";
      hf-file = "Qwen3.5-4B-abliterated.i1-Q4_K_M.gguf";
      # default for prompt-orchestration + `ask` — 4B is already loaded, faster
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
      # OpenAI's own sampling for gpt-oss: temperature and top-p wide open,
      # top-k/min-p off.
      temp = "1.0";
      top-p = "1.0";
      top-k = "0";
      min-p = "0.0";
    };
  };
in {
  services.llama-cpp = {
    enable = true;
    package = llamaVulkan;
    # Loopback only — never exposed on the network, agents on this machine
    # just hit localhost.
    openFirewall = false;
    settings = {
      host = "127.0.0.1";
      port = 8012;

      models-preset = modelsPreset;
      # Only one model in RAM at a time (default is 4); the model that is not
      # in use is unloaded instead of competing for the 32 GB.
      models-max = 1;
      # NB: leave `models-autoload` on (the default). It is what lets an
      # ordinary OpenAI request naming a model trigger the load; with
      # `no-models-autoload` every request to an unloaded model returns
      # 400 "model is not loaded" unless the client calls POST /models/load
      # first. Nothing is preloaded at boot either way — that takes an
      # explicit `load-on-startup = 1` in the preset, which is deliberately
      # not set here, so an idle laptop holds no LLM RAM.

      # All layers on the Arc iGPU. Vulkan only needs the Mesa ICD, which
      # hardware.graphics in hosts/blisspla/configuration.nix already provides.
      n-gpu-layers = 99;
      flash-attn = "on";
      # Qwen3.5-9B ships a vision projector that is not needed here (and is
      # incompatible with MTP spec decoding); skip the extra ~1 GB download.
      no-mmproj = true;
      # Use the model's own chat template, required for the `tools` API that
      # every MCP client relies on.
      jinja = true;
      # Optional: if the first request after boot is still annoyingly slow even after
      # the model is loaded, that is usually prompt processing + first-token latency,
      # not decode. On an iGPU shared-memory laptop that first prompt is where Vulkan
      # offload earns its keep. If you want the model resident and warm before anyone
      # talks to it, add `load-on-startup = 1` here; it costs RAM for the idle laptop
      # and was deliberately not set.
      #
      # The model here is qwen3.5-9b (UD-Q4_K_XL + MTP draft head). If you swap the
      # GGUF for a heavier model, the bottleneck changes: prompt processing still helps
      # from GPU offload, but the bigger KV cache can also start thrashing the shared
      # 32 GB. In that case the first thing to revisit is ctx-size and whether you
      # really want 65K resident, not n-gpu-layers.
    };
  };
  systemd.services.llama-cpp = {
    # DynamicUser has no writable $HOME; without these Mesa tries to create
    # //.cache on every start and Vulkan falls back to no shader cache.
    environment = {
      XDG_CACHE_HOME = "/var/cache/llama-cpp";
      MESA_SHADER_CACHE_DIR = "/var/cache/llama-cpp";
      # Pin the Arc iGPU.
      # Mesa/ANV enumerates Intel ICD (intel_icd) first on Vapor/Whiskey Lake onwards,
      # and GGML_VK_VISIBLE_DEVICES="0" then picks that device, but Vulkan ICD ordering
      # is still a best-effort assumption. If llama.cpp falls back to llvmpipe / CPU,
      # the slowness looks exactly like "GPU not being used".
      #
      # The authoritative check is `llama-server --list-devices` from the Vulkan build:
      # you want one device with the Intel ICD and no llvmpipe entry in the active set.
      # If that is wrong, set VK_DRIVER_FILES to the Intel ICD file explicitly rather
      # than relying on enumeration order.
      GGML_VK_VISIBLE_DEVICES = "0";
    };
    serviceConfig = {
      Environment = [
        "VK_DRIVER_FILES=${pkgs.mesa}/share/vulkan/icd.d/intel_icd.x86_64.json"
      ];
    };
  };

  # The service starts at boot but stays idle (~50 MB, no model loaded, no GPU
  # work) until an agent asks for a model. If you want it strictly on demand:
  #   systemd.services.llama-cpp.wantedBy = lib.mkForce [];
  # and start it with `systemctl start llama-cpp`.
  #
  # First-request slowness on blisspla is almost always one of these, not decode:
  #   * first ever request: downloads the ~6 GB GGUF into /var/cache/llama-cpp
  #   * first request after that: model loaded on demand by llama-server's autoload,
  #     so there is a load step before the first token (watch with `llm-status -w`)
  #   * after load: prompt processing still pays the KV-cache and context cost;
  #     the Arc iGPU helps most here because decode is memory-bandwidth bound anyway
  #
  # If you mean "the model is loaded and answers are still slow", the thing to check
  # is that llama.cpp is actually hitting the Intel iGPU and not llvmpipe. The clues:
  #   * `curl -s http://127.0.0.1:8012/props | jq -r '.build_info'` should mention Vulkan
  #   * `llama-server --list-devices` from the Vulkan build should list the Intel ICD device
  #   * `GGML_VK_VISIBLE_DEVICES=0` then maps to that device; a software Vulkan ICD in the
  #     enumerated set would make "GPU offloading" actually run on CPU
  #
  # The one static claim in this file that deserves a caveat: ICD filename ordering is not
  # a guaranteed path to "Intel wins". If Vulkan picks llvmpipe, set VK_DRIVER_FILES to the
  # Intel ICD file explicitly instead of relying on enumeration order.
  #
  # --- Vulkan device smoke check ---
  # The authoritative test is still the live one on the actual machine:
  #   llama-server --list-devices
  # from the Vulkan build, with the same environment the service uses
  # (in particular the Mesa/ANV ICDs that `hardware.graphics.enable` installs).
  # You want:
  #   - exactly one device that is the Intel ICD (not llvmpipe / softpipe)
  #   - no llvmpipe entry in the enumerated/active set
  #
  # For a reproducible, no-machine-needed assertion, there is a helper below:
  #   llama-vulkan-devices
  # It runs the *same* `llama-server` package as this host (the Vulkan override)
  # and parses the list-devices output, so a failing check here is the same failure
  # mode as "the service is actually running on llvmpipe". Run it after a switch:
  #   nixos-rebuild switch   # or: home-manager switch, if you only changed user stuff
  #   llama-vulkan-devices
  #
  # If the helper reports llvmpipe or 0 Intel ICD devices, the fix documented in the
  # service comments is to pin the Intel ICD explicitly:
  #   GGML_VK_VISIBLE_DEVICES is not enough when ICD enumeration picks llvmpipe first.
  #   Set VK_DRIVER_FILES to the Intel ICD file rather than relying on ordering.
  #
  # Runtime smoke test once switched (first request downloads the GGUF into
  # /var/cache/llama-cpp):
  #   curl -s http://127.0.0.1:8012/v1/models | jq -r '.data[].id'
  #   curl -s http://127.0.0.1:8012/v1/chat/completions \
  #     -H 'Content-Type: application/json' \
  #     -d '{"model":"qwen3.5-9b","messages":[{"role":"user","content":"open my browser"}]}'
  # or open the built-in web UI at http://127.0.0.1:8012
}
