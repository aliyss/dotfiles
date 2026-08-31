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
    # Free local AI that can drive Affinity on Linux/Hyprland.
    #   Ollama (brain) <-ollmcp-> computer-use-linux (hands+eyes MCP)
    # No Canva plan, no paid subscriptions.
    # =============================================================

    # --- Local model runtime (Ollama) as a user systemd service, mirroring
    #     the ydotool pattern in ./services/ydotool.nix.
    systemd.user.services.ollama = {
      Unit = {
        Description = "Ollama local LLM server";
        After = ["graphical-session.target"];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.ollama}/bin/ollama serve";
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    # Fetch the vision+tool model on first login (idempotent pull).
    systemd.user.services.ollama-firstload = {
      Unit = {
        Description = "Preload Ollama model";
        After = ["ollama.service"];
        Requires = ["ollama.service"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "ollama-load" ''
          set -euo pipefail
          ${pkgs.ollama}/bin/ollama pull qwen2.5vl:7b
        '';
      };
      Install.WantedBy = ["default.target"];
    };

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

      # --- MCP client for Ollama. Heavier Python closure (any-llm-sdk et al.),
      #     so run it via `uv tool` in an isolated environment instead of
      #     hand-deriving the whole dependency tree.
      (pkgs.writeShellScriptBin "ollmcp" ''
        set -euo pipefail
        ${pkgs.uv}/bin/uv tool install --force ollmcp
        exec ${pkgs.uv}/bin/uvx ollmcp "$@"
      '')
    ];

    # Register the computer-use-linux MCP server so ollmcp exposes its tools
    # (activate_window, click, type_text, screenshot, perform_action, ...) to the
    # local Qwen model. Path matches ollmcp's USER_MCP_FILE.
    home.file.".config/ollmcp/mcp.json".text = builtins.toJSON {
      mcpServers = {
        "computer-use-linux" = {
          command = "computer-use-linux";
          args = ["mcp"];
        };
      };
    };
  }