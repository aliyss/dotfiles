{
  pkgs,
  lib,
  ...
}: let
  commonPath = lib.makeBinPath (with pkgs; [curl jq gnused gnugrep coreutils systemd]);

  # ---------------------------------------------------------------------------
  # `ask` — one prompt in, one streamed answer out, on the terminal.
  #
  # Talks to whichever provider is answering on localhost. All three expose the
  # same OpenAI-compatible API, so only the base URL, the default model and
  # whether the endpoint has to be started first differ:
  #
  #   ask "…"              the on-machine llama.cpp model   :8012 (apps/local-llm.nix)
  #   ask -p deepseek "…"  chat.deepseek.com via a bridge    :8000 (apps/cloud-llm.nix)
  #   ask -p gemini "…"    gemini.google.com via a bridge    :8013 (apps/cloud-llm.nix)
  #
  # It exists mainly so the voice daemon can be pointed at a plain LLM instead
  # of `opencode run`: set `[command] template = 'ask "{prompt}"'` in
  # ~/.config/prompt-orchestration/config.toml and speaking ends with the answer
  # streaming into whatever terminal has focus. LLM_PROVIDER picks the default
  # when no `-p` is given.
  #
  # Tokens are printed as they arrive (SSE → jq). A cold local model is loaded
  # (and, the very first time, downloaded) before the first token — watch that
  # with `llm-status -w`. The cloud bridges are not started at boot either: the
  # first request starts one, and for a provider that has never run that also
  # means uv resolving (and downloading) its dependencies, so allow a minute.
  #
  #   ask what is the capital of australia
  #   ask -m gpt-oss-20b "explain the plan you just made"   # the slower, deeper MoE
  #   ask -p deepseek --think "why is the sky blue"
  #   ask -p gemini --search "what happened in the news today"
  #   echo "summarise this" | ask
  #
  # Thinking: qwen3.5-9b reasons by default, so `reasoning_content` carries the
  # scratch work and `content` the answer; we print content and fall back to the
  # reasoning rather than leaving a blank screen. Stray `<think>`/`</think>`
  # markers that leak into the stream are dropped. LOCAL_LLM_THINK=0 asks the
  # template for non-thinking mode, which is measurably broken with this GGUF
  # (it emits think tags only), so leave it unset unless experimenting. For the
  # cloud providers `--think` is their own reasoning mode (DeepThink / extended
  # thinking), which is a different knob entirely.
  #
  # Environment overrides:
  #   LLM_PROVIDER      local (default) | deepseek | gemini
  #   LOCAL_LLM_URL     default http://127.0.0.1:8012/v1
  #   DEEPSEEK_URL      default http://127.0.0.1:8000/v1
  #   GEMINI_URL        default http://127.0.0.1:8013/v1
  #   LOCAL_LLM_MODEL, DEEPSEEK_MODEL, GEMINI_MODEL   per-provider default model
  #   LLM_SYSTEM        optional system prompt (LOCAL_LLM_SYSTEM also works)
  #   LOCAL_LLM_THINK   1 = enable thinking, 0 = disable, unset = server default
  #   LOCAL_LLM_TIMEOUT curl timeout in seconds, default 1800
  # ---------------------------------------------------------------------------
  ask = pkgs.writeShellScriptBin "ask" ''
    set -euo pipefail
    # Absolute store paths: this also gets invoked by the voice daemon, whose
    # own environment is not a login shell.
    PATH="${commonPath}:$PATH"

    provider="''${LLM_PROVIDER:-local}"
    base=""
    model=""
    unit=""
    think=""
    search=false
    timeout="''${LOCAL_LLM_TIMEOUT:-1800}"
    system_prompt="''${LLM_SYSTEM:-''${LOCAL_LLM_SYSTEM:-}}"

    usage() {
      cat >&2 <<'EOF'
usage: ask [-p PROVIDER] [-m MODEL] [--think] [--search] <prompt>
       echo "..." | ask
providers: local (this machine, default), deepseek, gemini
EOF
    }

    while [ "$#" -gt 0 ]; do
      case "$1" in
        -p | --provider) provider="''${2:?ask: -p needs a provider}"; shift 2 ;;
        -m | --model) model="''${2:?ask: -m needs a model name}"; shift 2 ;;
        --think) think=true; shift ;;
        --search) search=true; shift ;;
        -h | --help) usage; exit 0 ;;
        --) shift; break ;;
        -*) echo "ask: unknown option '$1'" >&2; usage; exit 2 ;;
        *) break ;;
      esac
    done

    # `unit` is the systemd user unit that serves a cloud provider; it is empty
    # for the local model, which is a system service that runs on its own.
    case "$provider" in
      local | llama | llama.cpp)
        provider=local
        base="''${LOCAL_LLM_URL:-http://127.0.0.1:8012/v1}"
        model="''${model:-''${LOCAL_LLM_MODEL:-qwen3.5-4b}}"
        ;;
      deepseek | ds)
        provider=deepseek
        base="''${DEEPSEEK_URL:-http://127.0.0.1:8000/v1}"
        model="''${model:-''${DEEPSEEK_MODEL:-deepseek-chat}}"
        unit=deepseek-api
        ;;
      gemini | gem)
        provider=gemini
        base="''${GEMINI_URL:-http://127.0.0.1:8013/v1}"
        model="''${model:-''${GEMINI_MODEL:-gemini}}"
        unit=gemini-api
        ;;
      *)
        echo "ask: unknown provider '$provider' (try: local, deepseek, gemini)" >&2
        exit 2
        ;;
    esac

    if [ "$#" -gt 0 ]; then
      prompt="$*"
    else
      prompt="$(cat)"
    fi
    if [ -z "''${prompt//[[:space:]]/}" ]; then
      usage
      exit 2
    fi

    # Any HTTP status means the endpoint is up; 000 is curl's "could not
    # connect". A 503 from a cloud bridge (no cookies stored yet) still counts
    # as up — let the request itself carry the explanation.
    is_up() {
      # curl prints 000 and exits non-zero when it cannot connect, so an empty
      # or 000 code both mean "down"; anything else (including a 503 from a
      # bridge whose cookies are not set up) means the endpoint is listening.
      code="$(curl -s -o /dev/null --max-time 3 -w '%{http_code}' "$base/models" 2>/dev/null)"
      [ -n "$code" ] && [ "$code" != "000" ]
    }

    if ! is_up; then
      if [ -z "$unit" ]; then
        echo "ask: no llama.cpp server at $base — try: systemctl status llama-cpp" >&2
        exit 1
      fi
      # Cloud providers are started on demand (apps/cloud-llm.nix); the first
      # start of one that has never run also installs its dependencies.
      echo "ask: starting $unit … (logs: journalctl --user -u $unit -f)" >&2
      if ! systemctl --user start "$unit" 2>/dev/null; then
        echo "ask: could not start $unit — installed? (home-manager switch --flake ~/.config/flake#aliyss)" >&2
        exit 1
      fi
      tries=0
      until is_up || [ "$tries" -ge 90 ]; do
        sleep 1
        tries=$((tries + 1))
      done
      if ! is_up; then
        echo "ask: $unit did not answer within 90s — check: journalctl --user -u $unit -n 40" >&2
        exit 1
      fi
    fi

    if [ "$provider" = local ]; then
      # The model is loaded lazily on the first request that names it, and the
      # very first one downloads the GGUF, so do not sit in silence.
      status="$(curl -fsS --max-time 5 "$base/models" \
        | jq -r --arg m "$model" '.data[] | select(.id == $m or ((.aliases // []) | index($m))) | .status.value' \
        | head -n1)"
      if [ "$status" != "loaded" ]; then
        echo "ask: loading $model … (first run downloads it; watch with: llm-status -w)" >&2
      fi
    fi

    # LOCAL_LLM_THINK applies to whichever provider is chosen; --think is the
    # per-invocation switch.
    case "''${LOCAL_LLM_THINK:-}" in
      1 | on | true) think=true ;;
      0 | off | false) think=false ;;
    esac

    payload="$(jq -nc --arg m "$model" --arg p "$prompt" --arg s "$system_prompt" \
      --arg t "$think" --arg provider "$provider" --argjson search "$search" '
      {
        model: $m,
        stream: true,
        messages: ([{role: "system", content: $s}] | map(select(.content != "")))
                  + [{role: "user", content: $p}]
      }
      # Thinking is a chat-template flag on the local server, and DeepThink /
      # extended thinking on the cloud bridges.
      + (if $t == "" then {}
         elif $provider == "local" then {chat_template_kwargs: {enable_thinking: ($t == "true")}}
         else {thinking: ($t == "true")} end)
      + (if $search and $provider != "local" then {search: true} else {} end)
    ')"

    {
      # `content` first, `reasoning_content` as the fallback: a blank screen
      # is worse than showing the model's thinking.
      curl -sS -N --fail-with-body --max-time "$timeout" "$base/chat/completions" \
        -H 'Content-Type: application/json' \
        -d "$payload" \
        | sed -u 's/^data: //' \
        | { grep --line-buffered -vE '^(\[DONE\]|)$' || true; } \
        | jq --unbuffered -rj '
            # Error bodies are not SSE and carry no `data:` prefix, so they
            # arrive here intact: print what the server said (the bridges put
            # the fix in it, e.g. "run: gemini-auth") instead of a blank screen.
            if .error then "ask: " + (.error.message // (.error | tostring))
            elif .detail then "ask: " + (.detail | tostring)
            elif .choices then
              (.choices[0].delta | (.content // .reasoning_content // empty))
              # Some prompts make this GGUF leak raw `</think>` markers into
              # `content`; they are never part of the answer, so drop them as
              # they stream instead of printing tag soup.
              | gsub("<\\/?think>"; "")
            else empty
            end
          '
    } || {
      rc=$?
      # 22 is curl's "the server answered with an error status", and the
      # message above already explained it. Anything else (7 = could not
      # connect, 28 = timeout, a truncated stream) needs the generic hint.
      if [ "$rc" != 22 ]; then
        if [ -z "$unit" ]; then
          echo "ask: request to $model failed (curl $rc) — is llama-cpp healthy? (journalctl -u llama-cpp -n 30)" >&2
        else
          echo "ask: request to $model failed (curl $rc) — is $unit healthy? (journalctl --user -u $unit -n 30)" >&2
        fi
      fi
      # The filter prints without a trailing newline, so close the line it left
      # open before the shell prompt lands next to the error text.
      echo
      exit 1
    }
    echo
  '';

  # ---------------------------------------------------------------------------
  # `llm-status` — what the router is doing, without guessing.
  #
  # llama.cpp's router has no progress bar: `GET /v1/models` only reports
  # unloaded / loading / loaded per model (the 0..1 load fractions the child
  # sends to the router stay in the journal), and `/props` describes the
  # router itself. So this shows that state, how long a load has been going,
  # and what the load is actually doing right now — read from signals that do
  # not need root: RX bytes on the network interfaces (a download), the unit's
  # cgroup io.stat (reading the GGUF back in), cgroup memory growth (uploading
  # to the iGPU) and cgroup CPU time (init/shader compile). That makes a
  # silent stall obvious instead of looking like a very slow model.
  #
  #   llm-status        # one snapshot
  #   llm-status -w     # watch until every model is loaded
  # ---------------------------------------------------------------------------
  llmStatus = pkgs.writeShellScriptBin "llm-status" ''
    set -euo pipefail
    PATH="${commonPath}:$PATH"

    base="''${LOCAL_LLM_URL:-http://127.0.0.1:8012/v1}"
    root="''${base%/v1}"
    watch=0
    case "''${1:-}" in
      -w | --watch) watch=1 ;;
    esac

    # Where we remember when a model was first seen loading. Runtime dir keeps
    # it out of the way and it resets on logout.
    state_dir="''${XDG_RUNTIME_DIR:-/tmp}/llm-status"
    mkdir -p "$state_dir"

    # The systemd unit's cgroup: gives the model instance's CPU, I/O and RAM
    # without needing to own the process (the service runs as a DynamicUser).
    cg=""
    cgroup_path="$(systemctl show -p ControlGroup --value llama-cpp 2>/dev/null || true)"
    [ -n "$cgroup_path" ] && cg="/sys/fs/cgroup$cgroup_path"

    net_rx() { awk '{s += $1} END {print s+0}' /sys/class/net/*/statistics/rx_bytes 2>/dev/null || echo 0; }
    cg_cpu() { [ -n "$cg" ] && awk '/^usage_usec/ {print $2}' "$cg/cpu.stat" 2>/dev/null || echo 0; }
    cg_mem() { [ -n "$cg" ] && cat "$cg/memory.current" 2>/dev/null || echo 0; }
    cg_io() {
      [ -n "$cg" ] || { echo 0; return 0; }
      awk '{for (i = 1; i <= NF; i++) if ($i ~ /^[rw]bytes=/) {split($i, a, "="); s += a[2]}} END {print s+0}' "$cg/io.stat" 2>/dev/null || echo 0
    }

    # Sample over 2s and describe what is happening.
    activity() {
      local rx0 cpu0 io0 mem0 rx1 cpu1 io1 mem1
      rx0=$(net_rx); cpu0=$(cg_cpu); io0=$(cg_io); mem0=$(cg_mem)
      sleep 2
      rx1=$(net_rx); cpu1=$(cg_cpu); io1=$(cg_io); mem1=$(cg_mem)
      local rx=$(((rx1 - rx0) / 2097152)) io=$(((io1 - io0) / 2097152))
      local memrate=$(((mem1 - mem0) / 2097152)) cpu=$(((cpu1 - cpu0) / 20000))
      if [ "$rx" -ge 1 ]; then
        printf 'downloading ~%s MB/s' "$rx"
      elif [ "$io" -ge 1 ]; then
        printf 'reading the GGUF ~%s MB/s' "$io"
      elif [ "$memrate" -ge 5 ]; then
        printf 'copying to the iGPU (+%s MB/s)' "$memrate"
      elif [ "$cpu" -ge 5 ]; then
        printf 'initialising (CPU %s%%)' "$cpu"
      else
        printf 'NO ACTIVITY for 2s — stalled'
      fi
      awk -v m="$mem1" 'BEGIN {printf " | RAM %.1f GB", m/1073741824}'
    }

    if ! curl -fsS -o /dev/null --max-time 2 "$base/models"; then
      echo "llama-cpp: NOT reachable at $base"
      echo "  unit:  $(systemctl is-active llama-cpp 2>/dev/null || echo unknown) ($(systemctl is-enabled llama-cpp 2>/dev/null || echo unknown))"
      echo "  logs:  journalctl -u llama-cpp -n 30"
      exit 1
    fi

    snapshot() {
      local json props
      props="$(curl -fsS --max-time 5 "$root/props")"
      json="$(curl -fsS --max-time 5 "$base/models")"

      printf '%s  build=%s  autoload=%s  max_instances=%s\n' \
        "$root" \
        "$(jq -r '.build_info // "?"' <<<"$props" | cut -d' ' -f1)" \
        "$(jq -r '.models_autoload' <<<"$props")" \
        "$(jq -r '.max_instances' <<<"$props")"

      local loading=0
      while IFS=$'\t' read -r id st aliases; do
        local extra=""
        if [ "$st" = "loading" ]; then
          loading=1
          local f="$state_dir/$id.start" now start
          now=$(date +%s)
          [ -f "$f" ] || echo "$now" >"$f"
          start=$(cat "$f")
          extra="  $(activity)  elapsed $((now - start))s"
        else
          rm -f "$state_dir/$id.start"
        fi
        printf '  %-14s %-9s %s%s\n' "$id" "$st" "''${aliases:+aliases: $aliases}" "$extra"
      done < <(jq -r '.data[] | "\(.id)\t\(.status.value)\t\((.aliases // []) | join(","))"' <<<"$json")

      if [ "$loading" = 1 ]; then
        echo
        echo "  a cold model loads on the first request that names it and stays resident;"
        echo "  only the very first load downloads the GGUF (~6 GB, cached in /var/cache/llama-cpp)."
        echo "  stalled?  curl -s -X POST -H 'Content-Type: application/json' \\"
        echo "              -d '{\"model\": \"<id>\"}' $root/models/unload"
        echo "            then ask again — the router has no download timeout, so a dead"
        echo "            socket would sit at 'loading' forever."
      fi
    }

    if [ "$watch" = 0 ]; then
      snapshot
      exit 0
    fi

    while :; do
      printf '\n%s\n' "$(date +%H:%M:%S)"
      snapshot
      if ! curl -fsS --max-time 5 "$base/models" \
        | jq -e '[.data[].status.value] | any(. == "loading")' >/dev/null; then
        echo "  (all loaded)"
        exit 0
      fi
      sleep 3
    done
  '';
in {
  home.packages = [ask llmStatus];

  programs.fish.shellAbbrs = {
    # `ask gpt-oss-20b` is long to type when the 9B is not cutting it.
    askbig = "ask -m gpt-oss-20b";
    llms = "llm-status";
  };
}
