{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;

  # ===========================================================================
  # Cloud LLM alternatives to the on-machine model: your own free web accounts
  # for DeepSeek and Gemini, each behind a local OpenAI-compatible endpoint.
  #
  #   local (llama.cpp on the Arc iGPU)  http://127.0.0.1:8012/v1   see apps/local-llm.nix
  #   deepseek (chat.deepseek.com)       http://127.0.0.1:8000/v1
  #   gemini   (gemini.google.com)       http://127.0.0.1:8013/v1
  #
  # Why endpoints instead of a CLI: everything on this machine already speaks
  # the OpenAI API — `ask -p <provider>`, ollmcp, Avante, any MCP client — so a
  # provider is only useful once it answers at a /v1 URL. Two upstream projects
  # provide that, with very different amounts of help:
  #
  #   * sums001/Deepseek-API ships a FastAPI server (`app.py`) that logs into
  #     chat.deepseek.com with playwright and answers OpenAI-style. It solves
  #     DeepSeek's proof-of-work challenge in wasmtime. Pinned below.
  #   * HanaokaYuzu/Gemini-API ships a *library* (nothing but a CLI on top), so
  #     cloud-llm/gemini-bridge.py is the adapter: ~200 lines of FastAPI that
  #     turn chat completions into GeminiClient.generate_content_stream.
  #
  # Both use your own signed-in browser session, so both are free and both need
  # a one-time interactive login:
  #
  #   deepseek-auth     opens a browser; sign in, clear the human check
  #   gemini-auth       paste two cookies (or pull them out of Firefox)
  #
  # Neither service runs at boot. `ask -p deepseek` / `ask -p gemini` starts the
  # one it needs (see the provider table in apps/local-llm.nix) and leaves it
  # running, so an idle laptop pays nothing for them.
  #
  # Neither upstream supports tool calling — these are for when the local model
  # is too small or too slow, not a replacement for the MCP-facing router.
  # ===========================================================================

  # DeepSeek-API, pinned. It writes its session *inside* the source tree
  # (session/profile, session/session.json), and a store path is read-only, so
  # home.activation copies this into ~/.local/share/cloud-llm/deepseek/src.
  deepseekRev = "14d6227d2f0104038677872984eaddee59937e0e";
  deepseekSrc = pkgs.fetchFromGitHub {
    owner = "sums001";
    repo = "Deepseek-API";
    rev = deepseekRev;
    hash = "sha256-GtSWZ67y3sPKaLIpzPwCrGqlhsRFeG0n4bwDRJ4pzno=";
  };

  uv = "${pkgs.uv}/bin/uv";
  # Both projects need >=3.9 (DeepSeek) / >=3.11 (Gemini). 3.12 is what uv
  # fetches and what their dependencies have wheels for; the host's 3.14 is
  # untested by both.
  python = "3.12";

  # playwright is py-versioned against the browser builds it drives, and NixOS
  # cannot run the chromium that `playwright install` downloads (a dynamically
  # linked binary that expects /lib64). nixpkgs ships the matching patched
  # builds instead, so the pip version is pinned to theirs and pointed at them:
  # python playwright 1.61.0 wants chromium-1228 / ffmpeg-1011, and
  # playwright-driver 1.61.1 is exactly those revisions (checked against the
  # wheel's driver/package/browsers.json). `browsers` rather than
  # `browsers-chromium` because the session refresh runs headless, which needs
  # chromium_headless_shell.
  playwrightVersion = "1.61.0";
  playwrightBrowsers = pkgs.playwright-driver.browsers;

  home = config.home.homeDirectory;
  stateDir = "${home}/.local/share/cloud-llm";
  deepseekWork = "${stateDir}/deepseek";
  deepseekSrcDir = "${deepseekWork}/src";
  geminiConfig = "${home}/.config/gemini-webapi";
  geminiCookies = "${geminiConfig}/cookies.json";

  # Keep the uv command lines readable and in one place: the service and the
  # login helper must agree, or the helper authenticates an environment the
  # server never uses.
  uvRun = args: lib.concatStringsSep " " ([uv "run" "--no-project" "--python" python] ++ args);
  deepseekUv = uvRun [
    "--with-requirements"
    "${deepseekSrcDir}/requirements.txt"
    # Overrides requirements.txt's `playwright>=1.44`: any newer pip playwright
    # looks for browser revisions the store path above does not contain.
    "--with"
    "playwright==${playwrightVersion}"
    "python"
  ];

  # uv reads the PEP 723 block at the top of the file for dependencies, so
  # there is no separate lockfile to keep in sync. py_compile in the build
  # turns a typo into a failed `nix build` rather than a dead service.
  pythonFile = name: path:
    pkgs.runCommand name {
      nativeBuildInputs = [pkgs.python3];
    } ''
      install -m 0644 ${path} ${name}
      python3 -m py_compile ${name}
      install -m 0755 ${name} $out
    '';

  geminiBridge = pythonFile "gemini-bridge.py" ./cloud-llm/gemini-bridge.py;
  geminiAuthScript = pythonFile "gemini-auth.py" ./cloud-llm/gemini-auth.py;

  geminiEnv = [
    "HOST=127.0.0.1"
    "PORT=8013"
    "GEMINI_COOKIE_FILE=${geminiCookies}"
    # Keep the rotated __Secure-1PSIDTS beside the cookie file instead of the
    # library's /tmp default, so it survives a reboot.
    "GEMINI_COOKIE_PATH=${geminiConfig}"
    "PYTHONUNBUFFERED=1"
  ];

  deepseekEnv = [
    "HOST=127.0.0.1"
    "PORT=8000"
    # Outside the copied source tree on purpose: the copy is replaced whenever
    # the revision above changes, and that must not cost you the login.
    "DEEPSEEK_PROFILE_DIR=${deepseekWork}/profile"
    "PLAYWRIGHT_BROWSERS_PATH=${playwrightBrowsers}"
    "PYTHONUNBUFFERED=1"
  ];
in
  mkIf config.aliyss.profiles.llm {
    # The DeepSeek server reads its own source with a relative import and writes
    # `session/` next to it, so it has to run out of a writable copy. Everything
    # else about it is unchanged upstream.
    home.activation.cloudLlmSources = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ "$(cat "${deepseekWork}/.revision" 2>/dev/null)" != "${deepseekRev}" ]; then
        run mkdir -p "${deepseekWork}"
        run rm -rf "${deepseekSrcDir}"
        run cp -r ${deepseekSrc} "${deepseekSrcDir}"
        run chmod -R u+w "${deepseekSrcDir}"
        echo "${deepseekRev}" > "${deepseekWork}/.revision"
      fi
      # The upstream code mkdirs these itself; doing it here keeps the first
      # `deepseek-auth` from depending on a request having happened first.
      run mkdir -p "${deepseekSrcDir}/session" "${deepseekWork}/profile" "${geminiConfig}"
    '';

    home.packages = [
      # One-time logins. Both need a real terminal (and, for DeepSeek, a real
      # display): they are interactive by nature.
      (pkgs.writeShellScriptBin "deepseek-auth" ''
        set -euo pipefail
        if [ ! -d "${deepseekSrcDir}" ]; then
          echo "deepseek-auth: ${deepseekSrcDir} is missing — run: home-manager switch --flake ~/.config/flake#aliyss" >&2
          exit 1
        fi
        export DEEPSEEK_PROFILE_DIR="${deepseekWork}/profile"
        export PLAYWRIGHT_BROWSERS_PATH="${playwrightBrowsers}"
        cd "${deepseekSrcDir}"
        exec ${deepseekUv} -m deepseek.auth "$@"
      '')

      (pkgs.writeShellScriptBin "gemini-auth" ''
        set -euo pipefail
        export GEMINI_COOKIE_FILE="${geminiCookies}"
        exec ${uvRun [geminiAuthScript]} "$@"
      '')

      # Manual runs / debugging: the services are the normal entry point, but
      # foreground output is easier than journalctl when something breaks.
      (pkgs.writeShellScriptBin "gemini-api" ''
        set -euo pipefail
        ${lib.concatMapStringsSep "\n" (v: "export ${v}") geminiEnv}
        exec ${uvRun [geminiBridge]} "$@"
      '')
    ];

    systemd.user.services.deepseek-api = {
      Unit = {
        Description = "DeepSeek web API (OpenAI-compatible, your own free account)";
        After = ["network-online.target"];
      };
      Service = {
        Type = "simple";
        # Needed both as the module root for `server.api` and as the place the
        # source keeps its session files.
        WorkingDirectory = deepseekSrcDir;
        Environment = deepseekEnv;
        ExecStart = "${deepseekUv} app.py";
        Restart = "on-failure";
        RestartSec = 5;
      };
      # Deliberately no Install.WantedBy: started on demand by `ask -p deepseek`.
    };

    systemd.user.services.gemini-api = {
      Unit = {
        Description = "Gemini web API (OpenAI-compatible, your own free account)";
        After = ["network-online.target"];
      };
      Service = {
        Type = "simple";
        Environment = geminiEnv;
        ExecStart = uvRun [geminiBridge];
        # A failed request (no cookies yet) is answered with JSON, so a restart
        # loop here genuinely means something is wrong.
        Restart = "on-failure";
        RestartSec = 5;
      };
      # Started on demand by `ask -p gemini`.
    };

    programs.fish.shellAbbrs = {
      ds = "ask -p deepseek";
      gem = "ask -p gemini";
    };
  }
