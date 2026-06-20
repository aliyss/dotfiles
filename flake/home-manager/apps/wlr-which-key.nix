{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.aliyss.profiles;
  standaloneApps = config.aliyss.standaloneApps;
  host = ''$(hostname | sed "s/aliyss-//")'';
  currentHost = builtins.getEnv "HOSTNAME";
  isBlade = lib.hasInfix "blade" currentHost;

  yaml = pkgs.formats.yaml {};

  appsList = [
    {
      name = "affinity";
      key = "a";
      desc = "Affinity V3";
      cmd = "affinity-v3";
      profile = "creative";
    }
    {
      name = "blender";
      key = "b";
      desc = "Blender";
      cmd = "blender";
      profile = "creative";
    }
    {
      name = "davinci";
      key = "d";
      desc = "DaVinci Resolve";
      cmd = "davinci-resolve";
      profile = "creative";
    }
    {
      name = "obs";
      key = "o";
      desc = "OBS";
      cmd = "obs";
      profile = "creative";
    }
    {
      name = "heroic";
      key = "h";
      desc = "Heroic";
      cmd = "heroic";
      profile = "gaming";
    }
    {
      name = "steam";
      key = "s";
      desc = "Steam";
      cmd = "steam";
      profile = "gaming";
    }
  ];

  gatedEntry = app: let
    enabled = cfg.${app.profile} || elem app.name standaloneApps;
  in
    {
      key = app.key;
      desc = app.desc + optionalString (!enabled) " (Install)";
    }
    // (
      if enabled
      then {
        cmd = app.cmd;
      }
      else {
        submenu = [
          {
            key = "l";
            desc = "Launch ${app.desc}";
            cmd = app.cmd;
          }
          {
            key = app.key;
            desc = "Enable ${app.desc} only";
            cmd = "foot --title foot_install -e sh -c '$HOME/.config/flake/update-system -s ${host} -a +${app.name} && echo \"Done — press Enter to close\" && read _'";
          }
          {
            key = "i";
            desc = "Enable ${app.profile} (full suite)";
            cmd = "foot --title foot_install -e sh -c '$HOME/.config/flake/update-system -s ${host} -p +${app.profile} && echo \"Done — press Enter to close\" && read _'";
          }
        ];
      }
    );

  gatedApps = map gatedEntry (builtins.sort (a: b: a.cmd < b.cmd) appsList);
  enabledGated = filter (app: app ? cmd) gatedApps;
  disabledGated = filter (app: !(app ? cmd)) gatedApps;

  configData = {
    font = "JetBrainsMono Nerd Font 12";
    background = "#282828d0";
    color = "#fbf1c7";
    border = "#8ec07c";
    separator = " ➜ ";
    border_width = 1;
    corner_r = 0;
    padding = 15;
    rows_per_column = 14;
    column_padding = 25;

    anchor = "center";
    margin_right = 0;
    margin_bottom = 0;
    margin_left = 0;
    margin_top = 0;

    inhibit_compositor_keyboard_shortcuts = true;
    auto_kbd_layout = true;

    menu = [
      {
        key = "p";
        desc = "Power";
        submenu =
          [
            {
              key = "s";
              desc = "Shutdown";
              cmd = "shutdown -h 0";
            }
            {
              key = "r";
              desc = "Reboot";
              cmd = "reboot";
            }
            {
              key = "l";
              desc = "Lock";
              cmd = "hyprctl dispatch exit";
            }
          ]
          ++ lib.optionals isBlade [
            {
              key = "t";
              desc = "Toggle On/Off";
              cmd = "toggle-laptop-display.sh";
            }
          ];
      }
      {
        key = "s";
        desc = "System";
        submenu = let
          profileEntries =
            map (p: let
              toggle =
                if cfg.${p.name}
                then "-"
                else "+";
              toggleDesc =
                if cfg.${p.name}
                then "Disable"
                else "Enable";
            in {
              key = p.key;
              desc = "${toggleDesc} ${p.desc}";
              cmd = "foot --title foot_install -e sh -c '$HOME/.config/flake/update-system -s ${host} -p ${toggle}${p.name} && echo \"Done — press Enter to close\" && read _'";
            }) [
              {
                key = "l";
                name = "llm";
                desc = "LLM Tools";
              }
              {
                key = "c";
                name = "creative";
                desc = "Creative Apps";
              }
              {
                key = "g";
                name = "gaming";
                desc = "Gaming";
              }
              {
                key = "a";
                name = "audio";
                desc = "Audio Tools";
              }
            ];
          appEntries =
            imap0 (i: app: {
              key = toString (i + 1);
              desc = "Remove ${app}";
              cmd = "foot --title foot_install -e sh -c '$HOME/.config/flake/update-system -s ${host} -a -${app} && echo \"Done — press Enter to close\" && read _'";
            })
            standaloneApps;
        in
          profileEntries
          ++ optionals (standaloneApps != []) [
            {
              key = "r";
              desc = "Remove standalone apps";
              submenu = appEntries;
            }
          ];
      }
      {
        key = ["e"];
        desc = "Open Applications";
        submenu = let
          alwaysApps = [
            {
              key = "t";
              desc = "Terminal";
              cmd = "foot";
            }
            {
              key = "c";
              desc = "Browser";
              cmd = "firefox";
            }
            {
              key = "e";
              desc = "Neovim Screen";
              cmd = "foot -e tmux new -A -s nvim-screen";
            }
            {
              key = "y";
              desc = "Youtube Music";
              cmd = "pear-desktop";
            }
            {
              key = "m";
              desc = "Stremio";
              cmd = "stremio-linux-shell";
            }
            {
              key = "g";
              desc = "Gaming Mode";
              cmd = "foot -e tmux new -A -s gaming-screen ~/.config/hypr/scripts/gaming.sh";
            }
            {
              key = ["w"];
              desc = "Open Work Applications";
              submenu = [
                {
                  key = "t";
                  desc = "Microsoft Teams";
                  cmd = "teams-for-linux";
                }
                {
                  key = "s";
                  desc = "Slack";
                  cmd = "slack";
                }
              ];
            }
          ];
          allEnabled = builtins.sort (a: b: (a.cmd or "") < (b.cmd or "")) (alwaysApps ++ enabledGated);
        in
          allEnabled
          ++ optionals (disabledGated != []) [
            {
              key = "i";
              desc = "Install apps";
              submenu = disabledGated;
            }
          ];
      }
    ];
  };
in {
  home.file.".config/wlr-which-key/config.yaml".source = yaml.generate "wlr-which-key-config.yaml" configData;
}
