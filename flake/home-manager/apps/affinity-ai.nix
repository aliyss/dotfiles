{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
in
  mkIf config.aliyss.profiles.llm {
    # =============================================================
    # Free cloud AI that can drive Affinity on Linux/Hyprland.
    #   OpenRouter (brain) <-ollmcp-> computer-use-linux (hands+eyes MCP)
    # No local model runtime on this machine; no Canva plan or paid
    # subscriptions. Free OpenRouter models (e.g. minimax/minimax-m3:free)
    # need no credit card — limits are ~20 req/min and ~200 req/day.
    # =============================================================

    # --- Local Ollama runtime — DISABLED. The brain now talks to OpenRouter
    #     via ollmcp (below), so no local model server runs on this client.
    #     To bring the local Ollama brain back, uncomment the two services
    #     and drop the --provider/--model flags from the ollmcp wrapper.
    # systemd.user.services.ollama = {
    #   Unit = {
    #     Description = "Ollama local LLM server";
    #     After = ["graphical-session.target"];
    #   };
    #   Service = {
    #     Type = "simple";
    #     ExecStart = "${pkgs.ollama}/bin/ollama serve";
    #     Restart = "on-failure";
    #     RestartSec = 3;
    #   };
    #   Install.WantedBy = ["graphical-session.target"];
    # };
    #
    # # Fetch the vision+tool model on first login (idempotent pull).
    # systemd.user.services.ollama-firstload = {
    #   Unit = {
    #     Description = "Preload Ollama model";
    #     After = ["ollama.service"];
    #     Requires = ["ollama.service"];
    #   };
    #   Service = {
    #     Type = "oneshot";
    #     ExecStart = pkgs.writeShellScript "ollama-load" ''
    #       set -euo pipefail
    #       ${pkgs.ollama}/bin/ollama pull qwen2.5vl:7b
    #     '';
    #   };
    #   Install.WantedBy = ["default.target"];
    # };

    home.packages = [
      # --- Desktop-control MCP server: AT-SPI accessibility trees, screenshots,
      #     and click/type/scroll over Hyprland. Rust binary prefetched; wrapped
      #     so its runtime deps (ydotool, wtype, grim, slurp) are on PATH.
      (pkgs.runCommand "computer-use-linux" {
        src = pkgs.fetchurl {
          name = "computer-use-linux";
          url = "https://github.com/agent-sh/computer-use-linux/releases/download/v0.4.10/computer-use-linux-x86_64-unknown-linux-gnu";
          hash = "sha256-4HslahPdDYeJmorECbPJv2u9QHy0jP6URRTkOxLem1s=";
        };
        nativeBuildInputs = [pkgs.makeWrapper];
      } ''
        mkdir -p $out/bin
        # fetchurl output may lack the exec bit; copy + chmod, then wrap.
        install -m0755 "$src" "$out/bin/computer-use-linux-bin"
        makeWrapper "$out/bin/computer-use-linux-bin" "$out/bin/computer-use-linux" \
          --prefix PATH : "${pkgs.ydotool}/bin" \
          --prefix PATH : "${pkgs.wtype}/bin" \
          --prefix PATH : "${pkgs.grim}/bin" \
          --prefix PATH : "${pkgs.slurp}/bin"
      '')

      # --- MCP client driving OpenRouter. Heavier Python closure (any-llm-sdk
      #     et al.), so run it via `uv tool` in an isolated environment instead
      #     of hand-deriving the whole dependency tree.
      #     Talks to OpenRouter's free tier (no credit card) and forwards
      #     screenshots/tool calls to a vision+tool model. The API key is
      #     loaded straight from the flake's .env (or $OPENROUTER_API_KEY if
      #     already set) — ollmcp never writes it to disk. Override the model
      #     with $OLLMCP_MODEL.
      (pkgs.writeShellScriptBin "ollmcp" ''
        set -euo pipefail
        # Load the API key from the flake .env unless one is already set, so
        # this works before a re-login has applied home.sessionVariables.
        if [ -z "''${OPENROUTER_API_KEY:-}" ] && [ -f "$HOME/.config/flake/.env" ]; then
          line="$(grep '^OPENROUTER_API_KEY=' "$HOME/.config/flake/.env" | head -n1 || true)"
          if [ -n "$line" ]; then
            export OPENROUTER_API_KEY="''${line#OPENROUTER_API_KEY=}"
          fi
        fi
        ${pkgs.uv}/bin/uv tool install --force ollmcp
        exec ${pkgs.uv}/bin/uvx ollmcp \
          --provider openrouter \
          --model "''${OLLMCP_MODEL:-minimax/minimax-m3:free}" \
          "$@"
      '')
    ];

    # Register MCP servers so ollmcp exposes their tools to the OpenRouter
    # model. Path matches ollmcp's USER_MCP_FILE.
    #
    # "affinity" is Affinity 3.2's native AI-Automation MCP connector (SSE on
    # localhost:6767) — semantic, script-based control of Affinity docs, no
    # screenshots needed. Enable it in Affinity: Help > AI Automation.
    # (computer-use-linux, the screenshot/AT-SPI approach, is intentionally
    # NOT registered — screenshots are unused.)
    home.file.".config/ollmcp/mcp.json".text = builtins.toJSON {
      mcpServers = {
        "affinity" = {
          type = "sse";
          url = "http://localhost:6767/sse";
        };
      };
    };

    # Auto-loaded on startup (modelConfig.system_prompt) so the model knows
    # how to drive Affinity's scripting SDK without flailing. Provider/model
    # are injected by the wrapper below, so only the prompt is set here.
    # (Note: ollmcp's /save-config writes to this file; since home-manager
    # manages it as a read-only store link, prefer editing this module.)
    home.file.".config/ollmcp/config.json".text = builtins.toJSON {
      modelConfig = {
        system_prompt = ''
          You control the Affinity design application through its MCP scripting tools.

          1. Before writing any script, read the SDK documentation: call
             list_sdk_documentation, then read_sdk_documentation_topic with the
             exact filenames from the listing (e.g. "application", "document",
             "nodes", "story") and the working examples under "examples/".
          2. There is NO global "app" object. Access the app through modules:
             const { Document } = require('affinity:dom');
             const { DocumentCommandApi } = require('affinity:commands');
             Use Document.current for the open document and Document.all for
             all open documents. Enumerate layers via document.layers / rootNode.
          3. Use execute_script for one-off scripts. For reusable scripts use
             save_script_to_library (they appear in Affinity's Scripts panel),
             and list_library_scripts to see what's installed.
          4. Keep scripts short and synchronous. If a call returns an ErrorCode
             or throws, report it and adjust rather than guessing.
          5. Never guess API names or globals — confirm them in the SDK docs first.
        '';
      };
    };
  }