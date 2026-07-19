{
  config,
  pkgs,
  lib,
  herdr,
  hyprland,
  ...
}: let
  herdrPkg = herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
  herdrPluginDir = "${config.xdg.configHome}/herdr/plugins/vim-herdr-navigation";
  hyprctl = "${hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland}/bin/hyprctl";

  herdrWorkspace = pkgs.writeShellScriptBin "herdr-workspace" ''
    set -euo pipefail
    label="''${1:?usage: herdr-workspace <label>}"

    ${herdrPkg}/bin/herdr server 2>/dev/null &
    for _ in $(seq 1 30); do
      if ${herdrPkg}/bin/herdr workspace list >/dev/null 2>&1; then
        break
      fi
      sleep 0.2
    done

    id=$(${herdrPkg}/bin/herdr workspace list 2>/dev/null | ${pkgs.jq}/bin/jq -r \
      --arg label "$label" \
      '.result.workspaces[] | select(.label == $label) | .workspace_id' 2>/dev/null || :)
    if [ -n "$id" ]; then
      ${herdrPkg}/bin/herdr workspace focus "$id" 2>/dev/null || true
    else
      ${herdrPkg}/bin/herdr workspace create --label "$label" --focus 2>/dev/null || true
    fi

    exec ${herdrPkg}/bin/herdr
  '';

  herdrLaunch = pkgs.writeShellScriptBin "herdr-launch" ''
    set -euo pipefail
    label="''${1:?usage: herdr-launch <label>}"

    existing=$(${hyprctl} clients -j 2>/dev/null | ${pkgs.jq}/bin/jq -r \
      '.[] | select(.class == "foot" and .title == "herdr") | .address' 2>/dev/null | head -1)

    if [ -n "$existing" ]; then
      target_ws=$(${hyprctl} clients -j 2>/dev/null | ${pkgs.jq}/bin/jq -r \
        --arg addr "$existing" \
        '.[] | select(.address == $addr) | .workspace.name' 2>/dev/null)
      ${hyprctl} dispatch workspace "$target_ws" 2>/dev/null || true
      ${hyprctl} dispatch focuswindow "address:$existing" 2>/dev/null || true

      ${herdrPkg}/bin/herdr server 2>/dev/null &
      for _ in $(seq 1 30); do
        if ${herdrPkg}/bin/herdr workspace list >/dev/null 2>&1; then
          break
        fi
        sleep 0.2
      done

      id=$(${herdrPkg}/bin/herdr workspace list 2>/dev/null | ${pkgs.jq}/bin/jq -r \
        --arg label "$label" \
        '.result.workspaces[] | select(.label == $label) | .workspace_id' 2>/dev/null || :)
      if [ -n "$id" ]; then
        ${herdrPkg}/bin/herdr workspace focus "$id" 2>/dev/null || true
      else
        ${herdrPkg}/bin/herdr workspace create --label "$label" --focus 2>/dev/null || true
      fi

      exit 0
    fi

    exec foot -T "herdr" -e herdr-workspace "$label"
  '';
in {
  home.packages = [herdrPkg pkgs.jq herdrWorkspace herdrLaunch];

  # Plugin manifest
  home.file."${herdrPluginDir}/herdr-plugin.toml".text = ''
    id = "vim-herdr-navigation"
    name = "Vim Herdr Navigation"
    version = "0.1.0"
    min_herdr_version = "0.7.0"
    description = "Seamless Ctrl+h/j/k/l navigation across herdr panes and Vim/Neovim splits"
    platforms = ["linux", "macos"]

    [[actions]]
    id = "left"
    title = "Navigate left (Vim/herdr)"
    contexts = ["global"]
    command = ["bash", "navigate.sh", "left"]

    [[actions]]
    id = "down"
    title = "Navigate down (Vim/herdr)"
    contexts = ["global"]
    command = ["bash", "navigate.sh", "down"]

    [[actions]]
    id = "up"
    title = "Navigate up (Vim/herdr)"
    contexts = ["global"]
    command = ["bash", "navigate.sh", "up"]

    [[actions]]
    id = "right"
    title = "Navigate right (Vim/herdr)"
    contexts = ["global"]
    command = ["bash", "navigate.sh", "right"]
  '';

  # Navigation script (herdr side)
  home.file."${herdrPluginDir}/navigate.sh" = {
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      dir="''${1:?usage: navigate.sh <left|down|up|right>}"
      herdr="''${HERDR_BIN_PATH:-herdr}"
      pane="''${HERDR_PANE_ID:-}"

      case "$dir" in
        left)  key="ctrl+h" ;;
        down)  key="ctrl+j" ;;
        up)    key="ctrl+k" ;;
        right) key="ctrl+l" ;;
        *) echo "navigate.sh: unknown direction: $dir" >&2; exit 2 ;;
      esac

      vim_re='^g?(view|l?n?vim?x?)(diff)?$'
      passthrough_re="''${HERDR_NAV_PASSTHROUGH_RE:-}"

      forward=0
      if [ -n "$pane" ] && command -v jq >/dev/null 2>&1; then
        if "$herdr" pane process-info --current 2>/dev/null \
          | jq -e --arg vim "$vim_re" --arg pass "$passthrough_re" \
              '.result.process_info.foreground_processes[]?.name
               | ascii_downcase
               | select(test($vim) or ($pass != "" and (try test($pass) catch false)))' >/dev/null 2>&1; then
          forward=1
        fi
      fi

      if [ "$forward" -eq 1 ]; then
        exec "$herdr" pane send-keys "$pane" "$key"
      else
        exec "$herdr" pane focus --direction "$dir" --current
      fi
    '';
    executable = true;
  };

  # Herdr config with vim-herdr-navigation keybindings
  xdg.configFile."herdr/config.toml".text = ''
    onboarding = false

    [keys]
    prefix = "ctrl+space"

    [[keys.command]]
    key = "ctrl+h"
    type = "plugin_action"
    command = "vim-herdr-navigation.left"
    description = "navigate left (vim/herdr)"

    [[keys.command]]
    key = "ctrl+j"
    type = "plugin_action"
    command = "vim-herdr-navigation.down"
    description = "navigate down (vim/herdr)"

    [[keys.command]]
    key = "ctrl+k"
    type = "plugin_action"
    command = "vim-herdr-navigation.up"
    description = "navigate up (vim/herdr)"

    [[keys.command]]
    key = "ctrl+l"
    type = "plugin_action"
    command = "vim-herdr-navigation.right"
    description = "navigate right (vim/herdr)"

    [[keys.command]]
    key = "prefix+f"
    type = "plugin_action"
    command = "herdr-file-viewer.open-file-viewer"
    description = "open file viewer"

    [[keys.command]]
    key = "prefix+shift+f"
    type = "plugin_action"
    command = "herdr-file-viewer.open-file-viewer-tab"
    description = "open file viewer (tab)"

    [[keys.command]]
    key = "prefix+p"
    type = "plugin_action"
    command = "jt.command-palette.open"
    description = "command palette"

    [[keys.command]]
    key = "prefix+o"
    type = "plugin_action"
    command = "cloudmanic.herdr-plus.projects"
    description = "herdr-plus: projects"

    [[keys.command]]
    key = "prefix+shift+o"
    type = "plugin_action"
    command = "cloudmanic.herdr-plus.quick-actions"
    description = "herdr-plus: quick actions"

    [[keys.command]]
    key = "prefix+slash"
    type = "plugin_action"
    command = "persiyanov.reviewr.toggle"
    description = "reviewr: toggle code review sidebar"

    [terminal]
    default_shell = "fish"

    ${config.aliyss.themeGenerators.herdr}

    [advanced]
    scrollback_limit_bytes = 10485760

    [ui]
    mouse_capture = true
    pane_borders = true
    pane_gaps = true
  '';

  # Link plugin on activation if not already linked
  home.activation.linkHerdrPlugin = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if ${herdrPkg}/bin/herdr plugin list 2>/dev/null | grep -q "vim-herdr-navigation"; then
      :
    else
      ${herdrPkg}/bin/herdr plugin link "${herdrPluginDir}" 2>/dev/null || true
    fi
  '';
}
