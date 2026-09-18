{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf optionalAttrs elem;

  profiles = config.aliyss.profiles;

  # ===========================================================================
  # Prompt Orchestration — voice daemon with embedded intent router.
  #
  # Everything only starts after "hey alice" triggers.
  # - Wake word: hey alice (▁HE Y ▁A LI CE) only, no hey opencode/aider
  # - After wake: every pause -> intent (context-adjusted) -> action
  # - Intents are TOML per context in ~/.config/prompt-orchestration/intents/
  #   (firefox.toml, hyprland.toml, etc.), each file is a context.
  # - Conversation contexts auto-switch based on intent, with recency boost
  # - If nothing matches: fallback to LLM (ask), if LLM not loaded: "model isn't loaded"
  #
  # Binary comes from checkout (like nlp did), not Nix store:
  #   ~/Projects/prompt_orchestration/target/release/prompt-orchestration
  # Pure flake cannot see ~/Projects, so we check at runtime.
  # ===========================================================================
  projectDir = "${config.home.homeDirectory}/Projects/prompt_orchestration";
  binPath = "${projectDir}/target/release/prompt-orchestration";

  model = pkgs.callPackage ../../packages/potion-base-8M.nix { };

  hypr = cmd: "hyprctl dispatch 'hl.dsp.exec_cmd(\"${cmd}\")'";
  dsp = expr: "hyprctl dispatch '${expr}'";
  mpris = method: "p=$(busctl --user list --no-pager --no-legend 2>/dev/null | awk '$1 ~ /^org[.]mpris[.]MediaPlayer2/ {print $1; exit}'); [ -n \"$p\" ] && busctl --user call \"$p\" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player ${method}";

   mk = { id, description, action ? null, reply ? null, confirm ? description, utterances, threshold ? null, wait ? null, tags ? [ ], entities ? null }: { inherit id description confirm utterances; } // optionalAttrs (action != null) { inherit action; } // optionalAttrs (reply != null) { inherit reply; } // optionalAttrs (threshold != null) { inherit threshold; } // optionalAttrs (wait != null) { inherit wait; } // optionalAttrs (tags != [ ]) { inherit tags; } // optionalAttrs (entities != null) { inherit entities; };

   # ── intents per context ──────────────────────────────────────────────────
  # Firefox context (generic app.open handles launching; keep only tab close here)
  firefoxIntents = [
    (mk {
      id = "tab.close";
      description = "Close the current tab";
      action = "wtype -k ctrl+w 2>/dev/null || ydotool key 29:1 17:1 17:0 29:0 2>/dev/null || true";
      tags = [ "app" ];
      utterances = [ "close the tab" "close this tab" "close tab" "close it" "close that" "get rid of it" "shut this tab" ];
    })
  ];

  # Hyprland / window context - removed per request: hyprctl via fish completions -> LLM script
  hyprlandIntents = [];

  # Apps — single generic open with entity (closed list via shell)
  appsIntents = [
    (mk {
      id = "app.open";
      description = "Open an application (generic)";
      utterances = [ "open {app}" "launch {app}" "start {app}" "open the {app} app" "fire up {app}" "open {app} please" ];
      tags = [ "app" ];
      entities = {
        app = {
          open = false;
          values = "ls /run/current-system/sw/share/applications/*.desktop /usr/share/applications/*.desktop ~/.local/share/applications/*.desktop 2>/dev/null | xargs -n1 basename -s .desktop 2>/dev/null | sort -u; printf '%s\\n' firefox foot neovim yazi blender obs code terminal chromium";
          action = "$app";
          prompt = "Which app?";
        };
      };
    })
  ];

  gatedApps = [
    (mk { id = "app.affinity"; description = "Open Affinity V3"; confirm = "Opening Affinity"; action = hypr "affinity-v3"; tags = [ "app" "creative" ]; utterances = [ "open affinity" "launch affinity" "start affinity photo" "open the photo editor" ]; })
    (mk { id = "app.blender"; description = "Open Blender"; confirm = "Opening Blender"; action = hypr "blender"; tags = [ "app" "creative" ]; utterances = [ "open blender" "launch blender" "start blender" "let me do some 3d modelling" ]; })
    (mk { id = "app.davinci"; description = "Open DaVinci Resolve"; confirm = "Opening DaVinci Resolve"; action = hypr "davinci-resolve"; tags = [ "app" "creative" ]; utterances = [ "open davinci" "open davinci resolve" "start resolve" "open the video editor" ]; })
    (mk { id = "app.obs"; description = "Open OBS"; confirm = "Opening OBS"; action = hypr "obs"; tags = [ "app" "creative" ]; utterances = [ "open obs" "start obs" "open the screen recorder" "start recording the screen" ]; })
    (mk { id = "app.steam"; description = "Open Steam"; confirm = "Opening Steam"; action = hypr "steam"; tags = [ "app" "gaming" ]; utterances = [ "open steam" "launch steam" "start steam" "open my games" ]; })
    (mk { id = "app.heroic"; description = "Open Heroic"; confirm = "Opening Heroic"; action = hypr "heroic"; tags = [ "app" "gaming" ]; utterances = [ "open heroic" "launch heroic" "open epic games" "open my game launcher" ]; })
  ];

  gatedIntent = app: {
    "app.affinity" = profiles.creative || elem "affinity" config.aliyss.standaloneApps;
    "app.blender" = profiles.creative || elem "blender" config.aliyss.standaloneApps;
    "app.davinci" = profiles.creative || elem "davinci" config.aliyss.standaloneApps;
    "app.obs" = profiles.creative || elem "obs" config.aliyss.standaloneApps;
    "app.steam" = profiles.gaming || elem "steam" config.aliyss.standaloneApps;
    "app.heroic" = profiles.gaming || elem "heroic" config.aliyss.standaloneApps;
  }.${app.id} or true;

  # Navigation (as intents, not wake words) — single trigger "navigate" enters nav mode via router
  navigationIntents = [
    (mk {
      id = "mode.navigation";
      description = "Enter navigation mode";
      confirm = "Navigation mode";
      action = "__enter_navigation__";
      tags = [ "nav" ];
      utterances = [ "navigate" "navigation" "keybindings" "navigate mode" "enter navigation" ];
    })
    (mk { id = "nav.page_up"; description = "Page Up"; action = "ydotool key 104:1 104:0 || wtype -k Page_Up || true"; utterances = [ "page up" "navigate page up" "scroll up a page" "page up once" ]; })
    (mk { id = "nav.page_down"; description = "Page Down"; action = "ydotool key 109:1 109:0 || wtype -k Page_Down || true"; utterances = [ "page down" "navigate page down" "scroll down a page" "page down once" ]; })
    (mk { id = "nav.up"; description = "Up"; action = "ydotool key 103:1 103:0 || wtype -k Up || true"; utterances = [ "up" "move up" "go up" "navigate up" ]; })
    (mk { id = "nav.down"; description = "Down"; action = "ydotool key 108:1 108:0 || wtype -k Down || true"; utterances = [ "down" "move down" "go down" "navigate down" ]; })
    (mk { id = "nav.left"; description = "Left"; action = "ydotool key 105:1 105:0 || wtype -k Left || true"; utterances = [ "left" "move left" "go left" ]; })
    (mk { id = "nav.right"; description = "Right"; action = "ydotool key 106:1 106:0 || wtype -k Right || true"; utterances = [ "right" "move right" "go right" ]; })
    (mk { id = "nav.tab"; description = "Tab"; action = "ydotool key 15:1 15:0 || wtype -k Tab || true"; utterances = [ "tab" "press tab" "navigate tab" ]; })
    (mk { id = "nav.enter"; description = "Enter"; action = "ydotool key 28:1 28:0 || wtype -k Return || true"; utterances = [ "enter" "return" "press enter" "navigate enter" ]; })
    (mk { id = "nav.escape"; description = "Escape"; action = "ydotool key 1:1 1:0 || wtype -k Escape || true"; utterances = [ "escape" "esc" "press escape" ]; })
    (mk { id = "nav.backspace"; description = "Backspace"; action = "ydotool key 14:1 14:0 || wtype -k BackSpace || true"; utterances = [ "backspace" "delete backwards" ]; })
    (mk { id = "nav.space"; description = "Space"; action = "ydotool key 57:1 57:0 || wtype -k space || true"; utterances = [ "space" "press space" ]; })
    (mk { id = "nav.ctrl_c"; description = "Ctrl+C"; action = "ydotool key 29:1 46:1 46:0 29:0 || wtype -M ctrl -k c -m ctrl || true"; utterances = [ "ctrl c" "control c" "copy interrupt" "ctrl see" ]; })
  ];

  dictationIntents = [
    (mk {
      id = "mode.dictation";
      description = "Enter dictation";
      action = "__enter_dictation__";
      threshold = 0.78;
      tags = [ "dictation" ];
      utterances = [ "start typing" "start dictating" "start dictation" "dictation mode" "enter dictation mode" ];
    })
  ];

  # System, audio, media (as contexts)
  audioIntents = [
    (mk { id = "volume.up"; description = "Turn the volume up"; confirm = "Louder"; action = "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"; tags = [ "audio" ]; utterances = [ "turn it up" "louder" "raise the volume" "increase the volume" "turn up the sound" "make it louder" ]; })
    (mk { id = "volume.down"; description = "Turn the volume down"; confirm = "Quieter"; action = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"; tags = [ "audio" ]; utterances = [ "turn it down" "quieter" "lower the volume" "decrease the volume" "turn down the sound" "make it quieter" "quiet down a little" ]; })
    (mk { id = "volume.mute"; description = "Mute or unmute"; confirm = "Toggling mute"; action = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; tags = [ "audio" ]; utterances = [ "mute" "mute the sound" "silence it" "turn off the sound" "unmute the audio" ]; })
    (mk { id = "brightness.up"; description = "Increase the screen brightness"; confirm = "Brighter"; action = "brightnessctl -e4 -n2 set 5%+"; tags = [ "display" ]; utterances = [ "brighter" "make it brighter" "increase the brightness" "turn up the brightness" "the screen is too dark" "make the screen brighter" ]; })
    (mk { id = "brightness.down"; description = "Decrease the screen brightness"; confirm = "Dimmer"; action = "brightnessctl -e4 -n2 set 5%-"; tags = [ "display" ]; utterances = [ "dimmer" "dim the screen" "decrease the brightness" "lower the brightness" "the screen is too bright" ]; })
  ];

  mediaIntents = [
    (mk { id = "media.playpause"; description = "Play or pause whatever is playing"; confirm = "Toggling playback"; action = mpris "PlayPause"; tags = [ "media" ]; utterances = [ "pause the music" "resume the music" "toggle playback" "play or pause" "stop the music for a moment" ]; })
    (mk { id = "media.next"; description = "Skip to the next track"; confirm = "Next track"; action = mpris "Next"; tags = [ "media" ]; utterances = [ "next song" "skip this song" "next track" "play the next one" "skip ahead a track" "I do not like this song" ]; })
    (mk { id = "media.prev"; description = "Go back a track"; confirm = "Previous track"; action = mpris "Previous"; tags = [ "media" ]; utterances = [ "previous song" "go back a track" "previous track" "play the last song again" ]; })
  ];

  systemIntents = [
    (mk { id = "system.lock"; description = "Lock the screen"; action = "hyprlock"; tags = [ "system" ]; utterances = [ "lock the screen" "lock my computer" "lock it" "lock the session" "I am stepping away" ]; })
    (mk { id = "system.screenshot"; description = "Screenshot a region to the clipboard"; confirm = "Select the region to screenshot"; action = ''grim -g "$(slurp)" - | wl-copy''; tags = [ "system" ]; utterances = [ "take a screenshot" "screenshot" "grab a screenshot" "capture the screen" "screenshot that" "screenshot the region" ]; })
    (mk { id = "system.screenshot-full"; description = "Screenshot every monitor to the clipboard"; confirm = "Screenshotting all monitors"; action = "grim - | wl-copy"; tags = [ "system" ]; utterances = [ "screenshot the whole screen" "take a screenshot of everything" "screenshot all monitors" "capture the entire desktop" ]; })
    (mk { id = "system.suspend"; description = "Suspend the machine"; action = "systemctl suspend"; threshold = 0.68; tags = [ "system" ]; utterances = [ "suspend the computer" "go to sleep" "suspend" "put the machine to sleep" ]; })
    # health check disabled: was typing+submitting from dictation test (garbled "hello waodrdlda")
    # (mk { id = "system.health"; description = "Health check"; confirm = "Running health check"; action = "prompt-orchestration health || echo 'health check failed'"; tags = [ "system" ]; utterances = [ "health check" "check health" "system health" "is the system healthy" "run a health check" "show health" ]; })
    (mk { id = "llm.status"; description = "Show the local model status (llm-status)"; confirm = "Checking the local model"; action = "llm-status || true"; tags = [ "llm" ]; utterances = [ "how is the model doing" "is the model loaded" "model status" "check the local model" "is llama running" ]; })
  ];

  weatherIntents = [
    (mk {
      id = "weather.query";
      description = "Weather in a location";
      action = "curl \"wttr.in/{location}?format=3\"";
      tags = [ "weather" ];
      utterances = [ "what is the weather like in {location}" "what is the weather in {location}" "weather in {location}" "how is the weather in {location}" "tell me the weather in {location}" ];
      entities = {
        location = {
          open = true;
          prompt = "Which location?";
        };
      };
    })
  ];

  # Helper to generate TOML for a context
  tomlForContext = { id, description, intents }: ''
    [context]
    id = "${id}"
    description = "${description}"

    ${lib.concatMapStringsSep "\n" (intent: ''
      [[intent]]
      id = "${intent.id}"
      ${if intent ? description then "description = \"${intent.description}\"" else ""}
      ${if intent ? confirm then "confirm = \"${intent.confirm}\"" else ""}
      ${if intent ? action then "action = \"${lib.escape ["\"" "\\"] intent.action}\"" else ""}
      ${if intent ? threshold then "threshold = ${toString intent.threshold}" else ""}
      ${if intent ? wait then "wait = ${if intent.wait then "true" else "false"}" else ""}
      utterances = [ ${lib.concatMapStringsSep ", " (u: "\"${lib.escape ["\"" "\\"] u}\"") intent.utterances} ]
      ${if intent ? tags && intent.tags != [] then "tags = [ ${lib.concatMapStringsSep ", " (t: "\"${t}\"") intent.tags} ]" else ""}
      ${if intent ? entities then ''
        [intent.entities]
        ${lib.concatStringsSep "\n" (lib.attrsets.mapAttrsToList (name: def: ''
          [intent.entities.${name}]
          open = ${if def.open then "true" else "false"}
          ${if def ? values then "values = \"${lib.escape ["\"" "\\"] def.values}\"" else ""}
          ${if def ? action then "action = \"${lib.escape ["\"" "\\"] def.action}\"" else ""}
          ${if def ? prompt then "prompt = \"${lib.escape ["\"" "\\"] def.prompt}\"" else ""}
        '') intent.entities)}
      '' else ""}
    '') intents}
  '';

  # Config TOML — everything only starts after hey alice
  configToml = ''
    # Generated by flake/home-manager/apps/prompt-orchestration.nix — edit the module instead.
    # Everything only starts after "hey alice" triggers.

    [wake]
    word = "hey alice"
    aliases = []
    threshold = 0.50
    frame_ms = 80
    cooldown_ms = 1000
    consecutive_hits = 2

    [audio]
    sample_rate = 16000
    channels = 1
    endpoint_silence_ms = 600
    partial_debounce_ms = 40
    auto_detect = true

    [notifications]
    enabled = true
    timeout_ms = 2500
    on_wake = true
    on_submit = true
    on_error = true

    [stt]
    engine = "sherpa-onnx"
    model = "~/.local/share/prompt-orchestration/models"
    stream_chunk_ms = 700
    draft_engine = "auto"

    [edits]
    delete_triggers = ["scratch that","delete that","undo that","scratch it"]
    clear_triggers = ["clear","clear it","clear that","clear everything","clear the prompt","wipe"]
    submit_triggers = ["submit","run it","send it","go ahead","run command"]
    filler_words = ["um","uh","er","like","you know"]
    delete_scope = "clause"

    [intent_log]
    words = ["hey alice"]
    stop_words = ["stop","stop it","stop listening","that is all","that's all","we are done"]
    runner = 'sh -c "exit 3" -- "{prompt}"'
    fallback = 'LOCAL_LLM_THINK=0 ask -m qwen3.5-4b "{prompt}"'
    log = "~/.local/state/prompt-orchestration/session.log"
    # The name notifications are filed under.
    title = "alice"

    [gui]
    # alice-tauri: the overlay (marble + chat strip + input pill), three
    # compositor-placed windows over the GUI socket.
    enabled = true
    binary = "alice-tauri"
    socket = ""

    [router]
    model_dir = "${model}"
    intents_dir = "~/.config/prompt-orchestration/intents"
    threshold = 0.58
    candidates = 5
    shell = "sh"
    recent_context_boost = 0.08
    context_memory = 5
    context_timeout_ms = 120000

    [postprocess]
    llm = false

    [input]
    backend = "auto"
    type_delay_ms = 2
    clear_slack = 2

    [logging]
    level = "info"
  '';

  # Service wrapper — checks binary exists (checkout required)
  server = pkgs.writeShellScriptBin "prompt-orchestration-serve" ''
    bin="${binPath}"
    if [ ! -x "$bin" ]; then
      echo "prompt-orchestration: $bin is missing on this machine."
      echo "  build it once with: cd ~/Projects/prompt_orchestration && cargo build --release"
      echo "  then: systemctl --user restart prompt-orchestration"
      exit 0
    fi
    exec "$bin" listen
  '';

in
mkIf profiles.llm {
  xdg.configFile = {
    "prompt-orchestration/config.toml".text = configToml;
    "prompt-orchestration/intents/firefox.toml".text = tomlForContext { id = "firefox"; description = "Firefox browser"; intents = firefoxIntents; };
    # hyprland removed - hyprctl via fish completions -> LLM script only
    # "prompt-orchestration/intents/hyprland.toml".text = tomlForContext { id = "hyprland"; description = "Window management"; intents = hyprlandIntents; };
    "prompt-orchestration/intents/apps.toml".text = tomlForContext { id = "apps"; description = "Applications"; intents = appsIntents ++ builtins.filter (i: gatedIntent i) gatedApps; };
    "prompt-orchestration/intents/audio.toml".text = tomlForContext { id = "audio"; description = "Audio and brightness"; intents = audioIntents; };
    "prompt-orchestration/intents/media.toml".text = tomlForContext { id = "media"; description = "Media playback"; intents = mediaIntents; };
    "prompt-orchestration/intents/system.toml".text = tomlForContext { id = "system"; description = "System"; intents = systemIntents; };
    "prompt-orchestration/intents/weather.toml".text = tomlForContext { id = "weather"; description = "Weather queries"; intents = weatherIntents; };
    "prompt-orchestration/intents/navigation.toml".text = tomlForContext { id = "navigation"; description = "Navigation"; intents = navigationIntents; };
    "prompt-orchestration/intents/dictation.toml".text = tomlForContext { id = "dictation"; description = "Dictation mode"; intents = dictationIntents; };
  };

  systemd.user.services.prompt-orchestration = {
    Unit = {
      Description = "prompt-orchestration (voice daemon — hey alice only)";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
      # Everything only starts after hey alice triggers — service is idle until wake
    };
    Service = {
      Type = "simple";
      ExecStart = "${server}/bin/prompt-orchestration-serve";
      Restart = "always";
      RestartSec = 2;
      Environment = [
        "PATH=${config.home.homeDirectory}/.local/bin:${config.home.profileDirectory}/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin"
        "LD_LIBRARY_PATH=${config.home.homeDirectory}/.local/lib:/run/current-system/sw/share/nix-ld/lib:${pkgs.wayland}/lib:${pkgs.libxkbcommon}/lib:${pkgs.vulkan-loader}/lib:${pkgs.libGL}/lib"
        "NIX_LD_LIBRARY_PATH=/run/current-system/sw/share/nix-ld/lib:${pkgs.wayland}/lib:${pkgs.libxkbcommon}/lib:${pkgs.vulkan-loader}/lib:${pkgs.libGL}/lib"
        "YDOTOOL_SOCKET=/run/user/1000/.ydotool_socket"
        "RUST_LOG=info"
        "INTENT_MODEL_DIR=${model}"
        "PROMPT_MODEL_DIR=${model}"
        "LOCAL_LLM_THINK=0"
        "LOCAL_LLM_MODEL=qwen3.5-4b"
      ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # quick abbr for debugging intents
  programs.fish.shellAbbrs = {
    porr = "prompt-orchestration health";
  };
}
