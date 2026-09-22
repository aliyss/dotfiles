{
  pkgs,
  config,
  lib,
  aliyss-android-settings,
  ...
}:
# Declarative Android settings + hook services on the phone
# (aliyss.androidSettings), powered by the aliyss-android-settings repo.
#
# Same pattern as apps/android-pkgs.nix: the engine lives in its own repo
# (bin/android-settings + hooks/ + props/), home-manager only wires it up.
#
# The repo is consumed as the aliyss-android-settings flake input
# (github:aliyss/aliyss-android-settings, pinned in flake.lock and handed to
# every module by extraSpecialArgs = inputs), exactly like apps/android-pkgs.nix
# consumes aliyss-android-pkgs — a local `path:` input would break
# `nix flake lock` on the desktop, where that path doesn't exist.
#
# On every switch (after linkGeneration):
#   - props       -> rendered manifest, `android-settings apply` (root, via su)
#   - hooks       -> diff-installed as termux-services (runit) services named
#                    android-settings-<hook>; hooks removed from the list are
#                    uninstalled (state tracked in
#                    ~/.local/state/aliyss-android-settings/hooks)
#   - hookConfig  -> per-hook env file; changing it restarts the hook service
#
# A failed apply/install fails the switch loudly; failed removals only warn.
let
  isPhone = config.aliyss.isPhone;
  cfg = config.aliyss.androidSettings;

  # Engine package from the aliyss-android-settings flake input (see header).
  android-settings = aliyss-android-settings.packages.${pkgs.system}.android-settings;
  # The activation must call the engine by store path — the activation
  # script's PATH has no ~/.nix-profile/bin (the ~/.local/bin wrapper is
  # created post-switch by ensure-nix-wrappers.sh).
  engineBin = "${android-settings}/bin/android-settings";

  # Hooks shipped in the pack (used as the enum for the `hooks` option).
  availableHooks = builtins.attrNames
    (builtins.readDir "${android-settings}/share/android-settings/hooks");

  # Render the declared props as a manifest the engine can apply.
  # Keys are "namespace.key" (Android package-name charset — shell-safe).
  generatedProps = pkgs.writeText "aliyss-android-settings-generated.props"
    (lib.concatStringsSep "\n"
      (lib.mapAttrsToList (key: value: "${key} = ${value}") cfg.props)
    + "\n");

  # Per-hook env files (hookConfig). Keys must be valid POSIX var names;
  # values are single-quote-wrapped (with '\'' escaping) so values containing
  # spaces/quotes (e.g. shell command actions) survive sourcing.
  shQuote = v: "'" + lib.replaceStrings [ "'" ] [ "'\\''" ] v + "'";
  hookEnvFiles = lib.mapAttrs
    (name: env:
      pkgs.writeText "aliyss-android-settings-hook-${name}.env"
        (lib.concatStringsSep "\n"
          (lib.mapAttrsToList (k: v: "${k}=${shQuote v}") env) + "\n"))
    cfg.hookConfig;

  hookList = lib.concatStringsSep " " cfg.hooks;

  # Apps to disable (pm disable-user --user 0, reversible). Android package
  # names are [a-zA-Z0-9._] — safe for shell interpolation.
  disabledAppList = lib.concatStringsSep " " cfg.disabledApps;

  hookInstallLines = lib.concatStringsSep "\n" (map
    (name:
      let
        install =
          if lib.hasAttr name hookEnvFiles
          then "${engineBin} install-hook ${name} --env-file ${hookEnvFiles.${name}}"
          else "${engineBin} install-hook ${name}";
      in
      ''
        log "Installing android-settings hook: ${name}"
        ${install} || { echo "!! hook ${name} failed to install" >&2; exit 1; }
      '')
    cfg.hooks);
in
{
  options.aliyss.androidSettings = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable declarative Android settings + hook services on the phone
        (engine: aliyss-android-settings repo).
      '';
    };

    props = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = ''
        Android settings to apply on every switch, as "namespace.key" = value
        (namespace: global | system | secure). Applied with `settings put`
        via su. Example: "global.window_animation_scale" = "0.75".
      '';
    };

    hooks = lib.mkOption {
      type = lib.types.listOf (lib.types.enum availableHooks);
      default = [ ];
      description = ''
        Hooks from the aliyss-android-settings pack to run as termux-services
        (runit) services (android-settings-&lt;hook&gt;), autostarting at Termux
        boot. Hooks removed from this list are uninstalled on the next switch.
      '';
    };

    disabledApps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Android apps to disable (by package id, e.g.
        "com.nothing.ntessentialspace"), via `pm disable-user --user 0` —
        reversible, works for any app. Applied idempotently on every switch;
        ids removed from the list are re-enabled.
      '';
    };

    hookConfig = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
      default = { };
      description = ''
        Per-hook environment overrides (KEY = VALUE), e.g.
        hookConfig."battery-low".THRESHOLD = "10";. Written as an env file the
        hook's runit run script sources; changing it restarts the hook.
      '';
    };
  };

  config = lib.mkIf (isPhone && cfg.enable) {
    home.packages = [ android-settings ];

    # Disabled apps: diff against the previous declaration — enable the ids
    # that left the list, then (re-)disable the current list idempotently (so
    # a manual re-enable or an OS update flipping it back is corrected).
    home.activation.androidSettingsApps = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      state_file="$HOME/.local/state/aliyss-android-settings/disabled-apps"
      mkdir -p "$(dirname "$state_file")"

      log() { printf '\n\033[1;34m== %s ==\033[0m\n' "$*"; }
      warn() { printf '\033[1;33m!! %s\033[0m\n' "$*" >&2; }

      prev=""
      [ -f "$state_file" ] && prev="$(cat "$state_file")"
      curr="${disabledAppList}"

      # Re-enable apps that were disabled before but left the list.
      if [ -n "$prev" ]; then
        for pkg in $prev; do
          case " $curr " in
            *" $pkg "*) : ;;
            *)
              log "Re-enabling app (removed from aliyss.androidSettings.disabledApps): $pkg"
              ${engineBin} enable-app "$pkg" \
                || warn "could not re-enable $pkg (already gone?)"
              ;;
            esac
        done
      fi

      # Record before applying (same crash-safe pattern as the hooks).
      printf '%s\n' $curr >"$state_file"

      if [ -n "$curr" ]; then
        log "Disabling apps (aliyss.androidSettings.disabledApps)"
        ${engineBin} disable-app $curr || {
          echo "!! android-settings disable-app failed" >&2
          exit 1
        }
      fi
    '';

    # Props: apply the rendered manifest (root, via su inside the engine).
    home.activation.androidSettingsProps = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      log() { printf '\n\033[1;34m== %s ==\033[0m\n' "$*"; }

      log "Applying android settings (aliyss.androidSettings.props)"
      ${engineBin} apply ${generatedProps} || {
        echo "!! android-settings apply failed (su denied?)" >&2
        exit 1
      }
    '';

    # Hooks: diff-install (new list installs, removed ids uninstall), same
    # shape as the android-pkgs activation. Hook names come from the enum
    # ([a-z0-9_-]) — safe for shell interpolation.
    home.activation.androidSettingsHooks = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      state_file="$HOME/.local/state/aliyss-android-settings/hooks"
      mkdir -p "$(dirname "$state_file")"

      log() { printf '\n\033[1;34m== %s ==\033[0m\n' "$*"; }
      warn() { printf '\033[1;33m!! %s\033[0m\n' "$*" >&2; }

      prev=""
      [ -f "$state_file" ] && prev="$(cat "$state_file")"
      curr="${hookList}"

      # Remove hooks declared before but gone from the list.
      if [ -n "$prev" ]; then
        for name in $prev; do
          case " $curr " in
            *" $name "*) : ;;
            *)
              log "Removing android-settings hook: $name"
              ${engineBin} remove-hook "$name" \
                || warn "could not remove hook $name (already gone?)"
              ;;
          esac
        done
      fi

      # Record what we manage before installing, so a failed install re-runs
      # cleanly next time.
      printf '%s\n' $curr >"$state_file"

      # Install every declared hook (copy out of the store + runit service).
      ${hookInstallLines}
    '';
  };
}
