{ config, lib, pkgs, ... }:
let
  theme = config.aliyss.themeGenerators.youtube-music;

  # Shared, non-PC-specific settings. PC-specific state (url, window-*,
  # window-maximized) is written by the app and preserved on merge.
  sharedConfig = {
    __internal__.migrations.version = "3.12.0";
    options = {
      alwaysOnTop = false;
      appVisible = true;
      autoResetAppCache = false;
      autoUpdates = true;
      disableHardwareAcceleration = false;
      hideMenu = true;
      hideMenuWarned = true;
      likeButtons = "";
      overrideUserAgent = false;
      proxy = "";
      removeUpgradeButton = false;
      restartOnConfigChanges = false;
      resumeOnStart = true;
      startAtLogin = false;
      startingPage = "";
      themes = [
        "${config.xdg.configHome}/YouTube Music/theme.css"
      ];
      tray = false;
      trayClickPlayPause = false;
      usePodcastParticipantAsArtist = false;
    };
    plugins = {
      album-actions.enabled = false;
      album-color-theme.enabled = true;
      ambient-mode.enabled = true;
      blur-nav-bar.enabled = true;
      bypass-age-restrictions.enabled = true;
      discord = {
        activityTimeoutEnabled = true;
        activityTimeoutTime = 600000;
        autoReconnect = true;
        enabled = true;
        hideDurationLeft = false;
        hideGitHubButton = true;
        listenAlong = true;
        playOnYouTubeMusic = true;
        statusDisplayType = 2;
      };
      downloader.enabled = true;
      in-app-menu.enabled = false;
      navigation.enabled = true;
      notifications.enabled = true;
      precise-volume.globalShortcuts = {};
      sponsorblock.enabled = true;
      synced-lyrics.enabled = true;
      unobtrusive-player.enabled = true;
      video-toggle = {
        align = "left";
        enabled = true;
        forceHide = false;
        hideVideo = true;
        mode = "custom";
      };
      visualizer = {
        enabled = true;
        type = "wave";
        butterchurn = {
          preset = "martin [shadow harlequins shape code] - fata morgana";
          blendTimeInSeconds = 2.7;
          renderingFrequencyInMs = 500;
        };
        vudio = {
          effect = "lighting";
          accuracy = 128;
          lighting = {
            maxHeight = 160;
            maxSize = 12;
            lineWidth = 1;
            color = "#49f3f7";
            shadowBlur = 2;
            shadowColor = "rgba(244,244,244,.5)";
            fadeSide = true;
            prettify = false;
            horizontalAlign = "center";
            verticalAlign = "middle";
            dottify = true;
          };
        };
        wave.animations = [
          {
            type = "Cubes";
            config = {
              bottom = true;
              count = 30;
              cubeHeight = 5;
              fillColor = {
                gradient = [ "#FAD961" "#F76B1C" ];
              };
              lineColor = "rgba(0,0,0,0)";
              radius = 20;
            };
          }
          {
            type = "Cubes";
            config = {
              top = true;
              count = 12;
              cubeHeight = 5;
              fillColor = {
                gradient = [ "#FAD961" "#F76B1C" ];
              };
              lineColor = "rgba(0,0,0,0)";
              radius = 10;
            };
          }
          {
            type = "Circles";
            config = {
              lineColor = {
                gradient = [ "#FAD961" "#FAD961" "#F76B1C" ];
                rotate = 90;
              };
              lineWidth = 4;
              diameter = 20;
              count = 10;
              frequencyBand = "base";
            };
          }
        ];
      };
      shortcuts.enabled = true;
      do-not-track.enabled = true;
    };
  };

  sharedConfigFile = pkgs.writeText "youtube-music-config-shared.json" (builtins.toJSON sharedConfig);
in {
  xdg.configFile."YouTube Music/theme.css".text = theme;

  home.activation.mergeYouTubeMusicConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    configDir="$HOME/.config/YouTube Music"
    mkdir -p "$configDir"
    configFile="$configDir/config.json"
    if [ -f "$configFile" ]; then
      # Existing app state wins for keys nix doesn't define (url, window-*);
      # nix wins for every shared key (options, plugins).
      ${pkgs.jq}/bin/jq -s '.[1] * .[0]' "${sharedConfigFile}" "$configFile" > "$configFile.tmp" \
        && mv "$configFile.tmp" "$configFile"
    else
      cp "${sharedConfigFile}" "$configFile"
    fi
  '';
}
