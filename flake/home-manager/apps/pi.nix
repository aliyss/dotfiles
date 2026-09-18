{
  pkgs,
  lib,
  ...
}: let
  # Pi requires Node >=22.19.0 — nixpkgs nodejs_24 is 24.x, fine.
  # Wrapped via npx so it's Nix-defined but fetches from npm at first run
  # (like ollmcp via uv). Avoids building 97k-star TS monorepo in Nix.
  # If you prefer pure Nix build from GitHub, replace with buildNpmPackage.
  piBin = pkgs.writeShellScriptBin "pi" ''
    set -euo pipefail
    export NPM_CONFIG_UPDATE_NOTIFIER=false
    # Default pi to zen-proxy (OpenAI-compat) so `pi -p --provider openai --model mimo-v2.5-free` works without args
    if [ -z "''${OPENAI_BASE_URL:-}" ]; then
      export OPENAI_BASE_URL="http://127.0.0.1:8787/v1"
    fi
    if [ -z "''${OPENAI_API_KEY:-}" ]; then
      export OPENAI_API_KEY="public"
    fi
    # Also set pi-specific env if it uses OPENAI_API_BASE
    export OPENAI_API_BASE="''${OPENAI_BASE_URL}"
    exec ${pkgs.nodejs}/bin/npx -y @earendil-works/pi-coding-agent@0.85.1 "$@"
  '';

  # Wrapper that shows thinking in `-p` (print) mode — pi's `-p --mode text` hides thinking,
  # but `--mode json` streams `thinking_delta` events. This streams them live
  # into aider-like ► THINKING (oxocarbon dim) + ► ANSWER (oxocarbon accent),
  # and pretty-prints codeblocks at the end via `bat` (base16) + `glow` fallback.
  piThink = pkgs.writeShellScriptBin "pi-think" ''
        set -euo pipefail
        exec ${pkgs.nodejs}/bin/npx -y @earendil-works/pi-coding-agent@0.85.1 --mode json --thinking high "$@" 2>&1 | \
        ${pkgs.python3}/bin/python3 -u -c '
    import sys, json, subprocess, os, textwrap

    TEAL="\033[38;2;8;189;186m"
    DIM="\033[38;2;108;108;108m"
    RESET="\033[0m"
    BOLD="\033[1m"

    thinking_started=False
    answer_started=False
    answer_buf=""

    def pretty_markdown(md):
        # Try bat (base16) then glow, else plain
        for cmd in [["bat","--language","markdown","--style","plain","--color","always","--paging","never"],
                    ["glow","-s","dark"]]:
            try:
                p=subprocess.run(cmd, input=md.encode(), capture_output=True, timeout=5)
                if p.returncode==0 and p.stdout:
                    return p.stdout.decode(errors="ignore")
            except:
                continue
        return md

    for line in sys.stdin:
        line=line.strip()
        if not line:
            continue
        try:
            obj=json.loads(line)
        except:
            continue
        t=obj.get("assistantMessageEvent",{}).get("type") if obj.get("type")=="message_update" else None
        if t=="thinking_delta":
            if not thinking_started:
                sys.stdout.write(f"{DIM}{BOLD}► THINKING{RESET}{DIM}\n")
                thinking_started=True
            sys.stdout.write(DIM + obj["assistantMessageEvent"]["delta"] + RESET)
            sys.stdout.flush()
        elif t=="thinking_end":
            if thinking_started:
                sys.stdout.write(RESET)
                sys.stdout.flush()
        elif t=="text_delta":
            if not answer_started:
                sys.stdout.write(f"\n\n{TEAL}{BOLD}► ANSWER{RESET}\n")
                answer_started=True
                sys.stdout.flush()
            delta=obj["assistantMessageEvent"]["delta"]
            answer_buf+=delta
            sys.stdout.write(delta)
            sys.stdout.flush()
        elif obj.get("type")=="message_end" and obj.get("message",{}).get("role")=="assistant":
            if not thinking_started and not answer_started:
                for c in obj["message"]["content"]:
                    if c.get("type")=="thinking":
                        sys.stdout.write(f"{DIM}{BOLD}► THINKING{RESET}{DIM}\n"+c.get("thinking","")+f"{RESET}\n\n{TEAL}{BOLD}► ANSWER{RESET}\n")
                    elif c.get("type")=="text":
                        answer_buf+=c.get("text","")
                        sys.stdout.write(c.get("text",""))
                sys.stdout.flush()
            # If answer contained codeblocks, re-render pretty at end (streamed plain, now colored)
            if "```" in answer_buf:
                sys.stdout.write("\n\n" + DIM + "─" * 40 + RESET + "\n")
                # pretty via bat/glow
                pretty=pretty_markdown(answer_buf)
                # avoid duplicating if pretty is same as raw (bat may add colors)
                if pretty.strip() != answer_buf.strip():
                    sys.stdout.write(pretty)
                    sys.stdout.flush()
        '
  '';
in {
  home.packages = [
    piBin
    piThink
    pkgs.nodejs # ensure node >=22 for pi
    pkgs.delta # files-widget requires delta
    pkgs.glow # files-widget requires glow
    pkgs.bat # already via bat.nix, but ensure for pi
    pkgs.jq
  ];

  # Pi is configured via CLI flags / env, not a static JSON for baseUrl.
  # We keep no `~/.pi/config.json` by default — `pi` will use `OPENAI_BASE_URL`
  # + `OPENAI_API_KEY` from the wrapper below when you pass `--provider openai`.
  # To use zen-proxy explicitly: `pi --provider openai --model mimo-v2.5-free -p "hi"`
  # with `OPENAI_BASE_URL=http://127.0.0.1:8787/v1` (set in wrapper).
  # If you want a persistent `zen` provider, uncomment the block below and
  # check pi.dev docs for correct `~/.pi/settings.json` schema.
  # home.file.".pi/config.json".text = builtins.toJSON { ... };

  # ── Pi plugins: all of the above (Nix-defined via settings.json packages) ──
  # `pi install` is still available, but declaring here makes it reproducible.
  # Order matters: pi-mcp-adapter before pi-agent-plugins (MCP runtime).
  # Use activation copy (real file) so `pi` can still update lastChangelogVersion
  # without hitting a read-only store symlink.
  home.activation.piSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$HOME/.pi/agent"
    cat > "$HOME/.pi/agent/settings.json" <<'JSON'
    ${builtins.toJSON {
      lastChangelogVersion = "0.85.1";
      defaultProvider = "openrouter";
      defaultModel = "openrouter/free";
      theme = "oxocarbon";
      defaultThinkingLevel = "medium";
      hideThinkingBlock = false;
      outputPad = 4;
      editorPaddingX = 2;
      tuiMode = "fullscreen";
      packages = [
        "npm:pi-agent-extensions"
        "npm:pi-agent-suite"
        "npm:pi-mcp-adapter"
        "npm:pi-agent-plugins"
        "npm:@pi-vault/pi-plan"
        "npm:pi-extensions"
        "npm:pi-zentui"
        "npm:pi-rounded-tools"
        "/home/aliyss/Projects/pi-prompt-non-interactive-plugin"
      ];
    }}
    JSON
    chmod 644 "$HOME/.pi/agent/settings.json"
    # zentui layout — opencode preset gives framed editor + Starship footer + padding
    mkdir -p "$HOME/.pi/agent"
    cat > "$HOME/.pi/agent/zentui.json" <<'JSON'
    ${builtins.toJSON {
      components = {
        editor = {
          enabled = true;
          style = "opencode";
          colorSource = "theme";
          borderColorMode = "static";
          viewportIndicators = true;
        };
        userMessages = {
          enabled = true;
          style = "framed";
          colorSource = "theme";
        };
        footer = {
          style = "hidden";
          colorSource = "theme";
        };
        selectorBorders = {
          enabled = true;
          style = "zentui";
          colorSource = "theme";
        };
      };
    }}
    JSON
    chmod 644 "$HOME/.pi/agent/zentui.json"
  '';

  # Silence `ctrl+alt+p` conflict (pi-agent-suite structured-prompt vs pi-plan)
  # Pi picks pi-plan's, but prints warning. Patch the less-used one to ctrl+alt+o.
  home.activation.piPatchShortcuts = lib.hm.dag.entryAfter ["writeBoundary"] ''
    for f in "$HOME/.pi/agent/npm/node_modules/pi-agent-suite/extensions/structured-prompt/index.ts" "$HOME/.pi/agent/npm/node_modules/pi-agent-suite/extensions/structured-prompt/dist/index.js"; do
      if [ -f "$f" ]; then
        ${pkgs.gnused}/bin/sed -i 's/ctrlAlt("p")/ctrlAlt("o")/g; s/ctrl\+alt\+p/ctrl+alt+o/g' "$f" 2>/dev/null || true
      fi
    done
  '';

  programs.fish.shellAbbrs = lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) {
    pir = "pi -p";
    pit = "pi-think"; # pi -p but with ► THINKING visible (json → bat)
    piw = "pi --watch";
    pic = "pi --use-theme oxocarbon";
  };
}
