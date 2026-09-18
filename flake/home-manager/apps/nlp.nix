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
  # A local intent router (source: ~/Projects/intent-router).
  #
  # Voice input arrives as a sentence. "open firefox", "lock the screen" and
  # "next track" are commands, but they reach the same pipeline as "why is the
  # sky blue" and end up in a 9B model — seconds of latency, a GPU load and
  # context budget, for something the compositor does in two milliseconds.
  #
  # So the phrase hits ~30 registered intents first: each is a handful of
  # example utterances embedded with a static embedding model, and the incoming
  # phrase is scored against them by cosine similarity. Only what nothing
  # claims (below 0.58) is handed to the LLM, which is why the router can only
  # ever save work and never block a sentence.
  #
  # `intent "<phrase>"` is the front door — it runs the intent or execs `ask`.
  # MCPs do not go through the flake at all: they register their own intents at
  # runtime over the HTTP API on 127.0.0.1:8014 (POST /intents, see GET / for
  # the wire description), which is the whole point of the API existing.
  #
  # The binary comes out of the project checkout rather than the Nix store, the
  # same way prompt_orchestration runs itself:
  #
  #   * ~/Projects/intent-router/target/release/intent-router
  #
  # A pure flake cannot see a path outside its own tree (verified: `builtins.path`
  # on ~/Projects fails with "access to absolute path is forbidden in pure
  # evaluation mode", and both nixos-rebuild and home-manager here run without
  # --impure), so the checkout is the only way in without turning the project
  # into a committed flake input. The trade: `cargo build --release` instead of
  # a rebuild, and a service that explains itself if the binary is missing.
  # project.flake.nix exists for the other direction — consume it as
  # `git+file:` input and `services.intent-router.package` then points at the
  # store build.
  # ===========================================================================
  projectDir = "${config.home.homeDirectory}/Projects/intent-router";
  binPath = "${projectDir}/target/release/intent-router";

  model = pkgs.callPackage ../../packages/potion-base-8M.nix { };

  # ── how an action gets written ────────────────────────────────────────────
  # Launch a GUI app / run a command through the compositor. hyprctl returns as
  # soon as it has handed the command over, so the action still exits 0 and the
  # router can report a real failure instead of blocking on a window.
  # `cmd` must not contain a single quote: it lands inside the shell single
  # quotes below, and one there would end the argument early. Double quotes are
  # safe inside them.
  hypr = cmd: "hyprctl dispatch 'hl.dsp.exec_cmd(\"${cmd}\")'";
  # A raw lua dispatcher, for window/workspace actions. This Hyprland (0.55,
  # configType = lua in home.nix) rejects the classic `hyprctl dispatch
  # killactive` form — dispatch parses lua now.
  dsp = expr: "hyprctl dispatch '${expr}'";

  # Whatever is playing, instead of a hardcoded player: Spotify is not
  # installed here, pear-desktop (YouTube Music) is, and a browser tab exposes
  # MPRIS too. Silent no-op when nothing is playing.
  mpris = method: ''
    p=$(busctl --user list --no-pager --no-legend 2>/dev/null | awk '$1 ~ /^org[.]mpris[.]MediaPlayer2/ {print $1; exit}')
    [ -n "$p" ] && busctl --user call "$p" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player ${method}
  '';

  mk =
    {
      id,
      description,
      action ? null,
      reply ? null,
      confirm ? description,
      utterances,
      threshold ? null,
      wait ? null,
      tags ? [ ],
    }:
    {
      inherit id description confirm utterances;
    }
    // optionalAttrs (action != null) { inherit action; }
    // optionalAttrs (reply != null) { inherit reply; }
    // optionalAttrs (threshold != null) { inherit threshold; }
    // optionalAttrs (wait != null) { inherit wait; }
    // optionalAttrs (tags != [ ]) { inherit tags; };

  # ── apps ──────────────────────────────────────────────────────────────────
  appIntents = [
    (mk {
      id = "app.browser";
      description = "Open Firefox";
      confirm = "Opening Firefox";
      action = hypr "firefox";
      tags = [ "app" ];
      utterances = [
        "open firefox"
        "launch the browser"
        "start firefox"
        "open the web browser"
        "fire up a browser"
        "could you open the browser for me"
        "open a web browser"
        "I want to browse the web"
      ];
    })
    (mk {
      id = "app.terminal";
      description = "Open a herdr terminal";
      confirm = "Opening a terminal";
      action = hypr "herdr-launch Terminal";
      tags = [ "app" ];
      utterances = [
        "open a terminal"
        "launch the terminal"
        "start a shell"
        "give me a terminal"
        "bring up a shell"
        "get me a terminal window"
        "I need a shell"
      ];
    })
    (mk {
      id = "app.editor";
      description = "Open the herdr Neovim workspace";
      confirm = "Opening Neovim";
      action = hypr "herdr-launch Neovim";
      tags = [ "app" ];
      utterances = [
        "open neovim"
        "open my editor"
        "start vim"
        "open the code editor"
        "open nvim"
        "let me edit some code"
      ];
    })
    (mk {
      id = "app.files";
      description = "Open yazi in a terminal";
      confirm = "Opening the file manager";
      action = hypr "foot -e yazi";
      tags = [ "app" ];
      utterances = [
        "open the file manager"
        "show me my files"
        "open yazi"
        "browse my files"
        "open my home folder"
        "I need to see my files"
      ];
    })
    (mk {
      id = "app.music";
      description = "Open YouTube Music (pear-desktop)";
      confirm = "Opening YouTube Music";
      action = hypr "pear-desktop";
      tags = [ "app" "media" ];
      utterances = [
        "open youtube music"
        "open the music app"
        "launch my music player"
        "open pear desktop"
        "start youtube music"
      ];
    })
    (mk {
      id = "app.clipboard";
      description = "Open the clipse clipboard history";
      confirm = "Opening the clipboard";
      action = hypr "foot --title clipse_clipboard -e clipse";
      tags = [ "app" ];
      utterances = [
        "open the clipboard"
        "show my clipboard history"
        "clipboard history"
        "show me the clipboard"
        "what did I copy"
        "show me what I copied"
      ];
    })
    (mk {
      id = "app.mail";
      description = "Open himalaya in a terminal";
      confirm = "Opening my mail";
      action = hypr "foot --title Mail -e himalaya";
      tags = [ "app" ];
      utterances = [
        "open my email"
        "open my mail"
        "check my email"
        "open the mail client"
        "read my mail"
        "show me my inbox"
      ];
    })
    (mk {
      id = "app.teams";
      description = "Open Microsoft Teams";
      confirm = "Opening Teams";
      action = hypr "teams-for-linux";
      tags = [ "app" "work" ];
      utterances = [
        "open teams"
        "launch teams"
        "open microsoft teams"
        "start teams"
      ];
    })
    (mk {
      id = "app.mixer";
      description = "Open the audio mixer (pavucontrol)";
      confirm = "Opening the audio mixer";
      action = hypr "pavucontrol";
      tags = [ "app" "audio" ];
      utterances = [
        "open the audio mixer"
        "open the volume mixer"
        "open sound settings"
        "change which output is used"
        "open pavucontrol"
        "route the audio somewhere else"
      ];
    })
    (mk {
      id = "app.bluetooth";
      description = "Open the Bluetooth manager";
      confirm = "Opening Bluetooth settings";
      action = hypr "blueman-manager";
      tags = [ "app" ];
      utterances = [
        "open bluetooth"
        "open bluetooth settings"
        "connect a bluetooth device"
        "pair my headphones"
      ];
    })
    (mk {
      id = "app.vpn";
      description = "Open the VPN launcher";
      confirm = "Opening the VPN launcher";
      action = hypr "foot --title VPN -e vpn-launch";
      tags = [ "app" "network" ];
      utterances = [
        "open the vpn"
        "start the vpn"
        "connect to the vpn"
        "bring up the vpn"
        "launch the vpn client"
      ];
    })
    (mk {
      id = "app.remote";
      description = "Open the remote desktop launcher";
      confirm = "Opening the RDP launcher";
      action = hypr "foot --title RDP -e rdp-launch";
      tags = [ "app" "network" ];
      utterances = [
        "open remote desktop"
        "start remote desktop"
        "connect to my desktop"
        "open the rdp client"
        "remote into my desktop"
      ];
    })
  ];

  # ── apps that only exist with a profile ───────────────────────────────────
  # Same gating as the launcher menu (apps/wlr-which-key.nix): an app that is
  # not installed gets no intent, so a phrase can never match a command that
  # would only fail.
  gatedApps = [
    (mk {
      id = "app.affinity";
      description = "Open Affinity V3";
      confirm = "Opening Affinity";
      action = hypr "affinity-v3";
      tags = [ "app" "creative" ];
      utterances = [ "open affinity" "launch affinity" "start affinity photo" "open the photo editor" ];
    })
    (mk {
      id = "app.blender";
      description = "Open Blender";
      confirm = "Opening Blender";
      action = hypr "blender";
      tags = [ "app" "creative" ];
      utterances = [ "open blender" "launch blender" "start blender" "let me do some 3d modelling" ];
    })
    (mk {
      id = "app.davinci";
      description = "Open DaVinci Resolve";
      confirm = "Opening DaVinci Resolve";
      action = hypr "davinci-resolve";
      tags = [ "app" "creative" ];
      utterances = [ "open davinci" "open davinci resolve" "start resolve" "open the video editor" ];
    })
    (mk {
      id = "app.obs";
      description = "Open OBS";
      confirm = "Opening OBS";
      action = hypr "obs";
      tags = [ "app" "creative" ];
      utterances = [ "open obs" "start obs" "open the screen recorder" "start recording the screen" ];
    })
    (mk {
      id = "app.steam";
      description = "Open Steam";
      confirm = "Opening Steam";
      action = hypr "steam";
      tags = [ "app" "gaming" ];
      utterances = [ "open steam" "launch steam" "start steam" "open my games" ];
    })
    (mk {
      id = "app.heroic";
      description = "Open Heroic";
      confirm = "Opening Heroic";
      action = hypr "heroic";
      tags = [ "app" "gaming" ];
      utterances = [ "open heroic" "launch heroic" "open epic games" "open my game launcher" ];
    })
  ];

  # Keyed by intent id: the attribute is looked up with `app.id`, so a typo here
  # would fall through to the `or true` and quietly reintroduce an intent for an
  # app that is not installed.
  gatedIntent = app: {
    "app.affinity" = profiles.creative || elem "affinity" config.aliyss.standaloneApps;
    "app.blender" = profiles.creative || elem "blender" config.aliyss.standaloneApps;
    "app.davinci" = profiles.creative || elem "davinci" config.aliyss.standaloneApps;
    "app.obs" = profiles.creative || elem "obs" config.aliyss.standaloneApps;
    "app.steam" = profiles.gaming || elem "steam" config.aliyss.standaloneApps;
    "app.heroic" = profiles.gaming || elem "heroic" config.aliyss.standaloneApps;
  }
  .${app.id}
  or true;

  # ── windows and workspaces ────────────────────────────────────────────────
  windowIntents = [
    (mk {
      id = "window.close";
      description = "Close the focused window";
      action = dsp "hl.dsp.window.close()";
      # Higher cut-off on purpose: a wrong match here closes someone's work.
      threshold = 0.72;
      tags = [ "window" ];
      utterances = [
        "close this window"
        "close the window"
        "kill this window"
        "shut this window"
        "get rid of this window"
      ];
    })
    (mk {
      id = "window.fullscreen";
      description = "Toggle fullscreen for the focused window";
      action = dsp "hl.dsp.window.fullscreen()";
      tags = [ "window" ];
      utterances = [
        "make it fullscreen"
        "fullscreen this"
        "toggle fullscreen"
        "make this window full screen"
        "exit fullscreen"
      ];
    })
    (mk {
      id = "window.float";
      description = "Toggle floating for the focused window";
      action = dsp "hl.dsp.window.float({ action = \"toggle\" })";
      tags = [ "window" ];
      utterances = [
        "float this window"
        "make this window float"
        "toggle floating"
        "let this window float"
      ];
    })
    (mk {
      id = "workspace.next";
      description = "Go to the next workspace";
      action = dsp "hl.dsp.focus({ workspace = \"e+1\" })";
      tags = [ "window" ];
      utterances = [
        "next workspace"
        "go to the next workspace"
        "move to the next desktop"
        "switch workspace"
      ];
    })
    (mk {
      id = "workspace.prev";
      description = "Go to the previous workspace";
      action = dsp "hl.dsp.focus({ workspace = \"e-1\" })";
      tags = [ "window" ];
      utterances = [
        "previous workspace"
        "go back a workspace"
        "go to the previous desktop"
        "switch back"
      ];
    })
  ];

  # ── system, audio, media ──────────────────────────────────────────────────
  systemIntents = [
    (mk {
      id = "system.lock";
      description = "Lock the screen";
      action = "hyprlock";
      tags = [ "system" ];
      utterances = [
        "lock the screen"
        "lock my computer"
        "lock it"
        "lock the session"
        "I am stepping away"
      ];
    })
    (mk {
      id = "system.screenshot";
      description = "Screenshot a region to the clipboard";
      confirm = "Select the region to screenshot";
      action = ''grim -g "$(slurp)" - | wl-copy'';
      tags = [ "system" ];
      utterances = [
        "take a screenshot"
        "screenshot"
        "grab a screenshot"
        "capture the screen"
        "screenshot that"
        "screenshot the region"
      ];
    })
    (mk {
      id = "system.screenshot-full";
      description = "Screenshot every monitor to the clipboard";
      confirm = "Screenshotting all monitors";
      action = "grim - | wl-copy";
      tags = [ "system" ];
      utterances = [
        "screenshot the whole screen"
        "take a screenshot of everything"
        "screenshot all monitors"
        "capture the entire desktop"
      ];
    })
    (mk {
      id = "system.suspend";
      description = "Suspend the machine";
      action = "systemctl suspend";
      threshold = 0.68;
      tags = [ "system" ];
      utterances = [
        "suspend the computer"
        "go to sleep"
        "suspend"
        "put the machine to sleep"
      ];
    })
    (mk {
      id = "volume.up";
      description = "Turn the volume up";
      confirm = "Louder";
      action = "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+";
      tags = [ "audio" ];
      utterances = [
        "turn it up"
        "louder"
        "raise the volume"
        "increase the volume"
        "turn up the sound"
        "make it louder"
      ];
    })
    (mk {
      id = "volume.down";
      description = "Turn the volume down";
      confirm = "Quieter";
      action = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
      tags = [ "audio" ];
      utterances = [
        "turn it down"
        "quieter"
        "lower the volume"
        "decrease the volume"
        "turn down the sound"
        "make it quieter"
        "quiet down a little"
      ];
    })
    (mk {
      id = "volume.mute";
      description = "Mute or unmute";
      confirm = "Toggling mute";
      action = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      tags = [ "audio" ];
      utterances = [
        "mute"
        "mute the sound"
        "silence it"
        "turn off the sound"
        "unmute the audio"
      ];
    })
    (mk {
      id = "brightness.up";
      description = "Increase the screen brightness";
      confirm = "Brighter";
      action = "brightnessctl -e4 -n2 set 5%+";
      tags = [ "display" ];
      utterances = [
        "brighter"
        "make it brighter"
        "increase the brightness"
        "turn up the brightness"
        "the screen is too dark"
        "make the screen brighter"
      ];
    })
    (mk {
      id = "brightness.down";
      description = "Decrease the screen brightness";
      confirm = "Dimmer";
      action = "brightnessctl -e4 -n2 set 5%-";
      tags = [ "display" ];
      utterances = [
        "dimmer"
        "dim the screen"
        "decrease the brightness"
        "lower the brightness"
        "the screen is too bright"
      ];
    })
    (mk {
      id = "media.playpause";
      description = "Play or pause whatever is playing";
      confirm = "Toggling playback";
      action = mpris "PlayPause";
      tags = [ "media" ];
      utterances = [
        "pause the music"
        "resume the music"
        "toggle playback"
        "play or pause"
        "stop the music for a moment"
      ];
    })
    (mk {
      id = "media.next";
      description = "Skip to the next track";
      confirm = "Next track";
      action = mpris "Next";
      tags = [ "media" ];
      utterances = [
        "next song"
        "skip this song"
        "next track"
        "play the next one"
        "skip ahead a track"
        "I do not like this song"
      ];
    })
    (mk {
      id = "media.prev";
      description = "Go back a track";
      confirm = "Previous track";
      action = mpris "Previous";
      tags = [ "media" ];
      utterances = [
        "previous song"
        "go back a track"
        "previous track"
        "play the last song again"
      ];
    })
    # The LLM tools have their own intents too: "how is the model doing" is a
    # status check, not a question for the model. The output comes back through
    # the router and the front door prints it, which is why this works with no
    # terminal involved. `|| true` keeps an unreachable llama.cpp from looking
    # like a failed action — llm-status already says so in its output.
    (mk {
      id = "llm.status";
      description = "Show the local model status (llm-status)";
      confirm = "Checking the local model";
      action = "llm-status || true";
      tags = [ "llm" ];
      utterances = [
        "how is the model doing"
        "is the model loaded"
        "model status"
        "check the local model"
        "is llama running"
      ];
    })
  ];

  intents =
    appIntents
    ++ builtins.filter (i: gatedIntent i) gatedApps
    ++ windowIntents
    ++ systemIntents;

  coreIntentsJson = builtins.toJSON {
    _comment = [
      "Generated by flake/home-manager/apps/nlp.nix — edit the module, not this file."
      "Add machine-local intents as extra *.json beside it (the directory is read whole),"
      "or let an MCP register them at runtime over the API (POST /intents)."
      "Format reference: ~/Projects/intent-router/intents/example.json"
    ];
    inherit intents;
  };

  configToml = ''
    # Generated by flake/home-manager/apps/nlp.nix — this file is a store
    # symlink, so edit the module instead. Everything here can also be set
    # per-run through the matching INTENT_* environment variable, which wins.

    [server]
    host = "127.0.0.1"
    port = 8014

    [model]
    dir = "${model}"

    [intents]
    paths = [ "~/.config/intent-router/intents" ]
    state = "~/.local/state/intent-router/intents.json"

    [router]
    threshold = 0.58
    candidates = 5

    [exec]
    shell = "sh"
  '';

  # The service entry point. A missing binary is a *quiet* failure on purpose:
  # exit 0 with the fix in the journal instead of a restart loop that spams it,
  # because on the two hosts that do not have the checkout this unit is inert.
  server = pkgs.writeShellScriptBin "intent-router-serve" ''
    bin="${binPath}"
    if [ ! -x "$bin" ]; then
      echo "intent-router: $bin is missing on this machine."
      echo "  build it once with:  cd ~/Projects/intent-router && cargo build --release"
      echo "  then:  systemctl --user restart intent-router"
      exit 0
    fi
    exec "$bin" listen
  '';

  # Same binary, with an answer instead of ENOENT when it has not been built.
  nlp = pkgs.writeShellScriptBin "nlp" ''
    bin="${binPath}"
    if [ ! -x "$bin" ]; then
      echo "nlp: $bin is missing — build it: cd ~/Projects/intent-router && cargo build --release" >&2
      exit 1
    fi
    exec "$bin" "$@"
  '';

  # `intent` — one phrase in. Runs it if an intent claims it, hands it to the
  # LLM otherwise. Only exit 3 (nothing matched, which includes "the router is
  # not running") falls through; 0 and 4 already happened and must not also be
  # sent to the LLM.
  frontDoor = pkgs.writeShellScriptBin "intent" ''
    if [ "$#" -eq 0 ]; then
      echo "usage: intent <phrase>" >&2
      exit 2
    fi
    bin="${binPath}"
    if [ ! -x "$bin" ]; then
      exec ask "$@"
    fi
    rc=0
    "$bin" run "$@" || rc=$?
    case "''${rc}" in
      3) exec ask "$@" ;;
      *) exit "''${rc}" ;;
    esac
  '';
in
mkIf profiles.llm {
  xdg.configFile = {
    "intent-router/config.toml".text = configToml;
    "intent-router/intents/core.json".text = coreIntentsJson;
  };

  home.packages = [ nlp frontDoor ];

  systemd.user.services.intent-router = {
    Unit = {
      Description = "intent-router (local phrase → intent router, HTTP API on :8014)";
      # The actions are hyprctl / wpctl / brightnessctl / systemctl, so the
      # service needs the session environment the compositor exports
      # (HYPRLAND_INSTANCE_SIGNATURE, WAYLAND_DISPLAY, the session bus).
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${server}/bin/intent-router-serve";
      Restart = "on-failure";
      RestartSec = 2;
      Environment = [
        # A user service does not inherit a login shell's PATH.
        "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin"
        # The weights from the flake (see packages/potion-base-8M.nix). In the
        # environment as well as the config file because it is a store path:
        # there is then no way to point the router at weights that are gone.
        "INTENT_MODEL_DIR=${model}"
      ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  programs.fish.shellAbbrs = {
    # `nlp` itself is short enough; this is the one subcommand worth abbreviating,
    # because tuning an intent means asking it over and over what a phrase hits.
    irr = "nlp route";
  };
}
