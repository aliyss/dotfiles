{
  pkgs,
  config,
  lib,
  aliyss-android-pkgs,
  ...
}:
# Declarative Android app installs on the phone (aliyss.androidPkgs).
#
# Apps come from the aliyss-android-pkgs flake input, which flake/flake.nix
# re-exports as flake.packages.<system> — every pinned app-id is a buildable
# derivation on the phone. Declare the app-ids you want installed and every
# `home-manager switch` ensures exactly those are installed:
#
#   aliyss.androidPkgs = [
#     "com.darkempire78.opencalculator"
#     "org.videolan.vlc"
#   ];
#
# Installation lives in the aliyss-android-pkgs repo itself — scripts/
# install.sh, exposed as packages.<system>.android-install — so there is no
# per-user install script. This module just runs it in on-device mode (-d):
#
#   - apps declared now are built (from the dotfiles flake, -f, which pins the
#     android-pkgs input) and pm-installed as root on switch;
#   - apps declared on a previous switch but removed from the list are
#     uninstalled (the previous declaration is tracked in
#     ~/.local/state/aliyss-android-pkgs);
#   - the install is bounded at 60s so a Google Play Protect block is reported
#     instead of hanging the switch.
#
# A failed install fails the switch loudly (fix it — e.g. allow the app in
# Play Protect — and re-run update-home); failed uninstalls only warn.
#
# Phone-only: this module is imported only by flake/hosts/termux/home.nix.
let
  isPhone = config.aliyss.isPhone;
  cfg = config.aliyss.androidPkgs;
  # The repo's installer, added to home.packages so it is linked into
  # ~/.nix-profile/bin (and wrapped into ~/.local/bin by ensure-nix-wrappers.sh,
  # giving the phone its install-app / uninstall-app commands).
  installer = aliyss-android-pkgs.packages.${pkgs.system}.android-install;
  appList = lib.concatStringsSep " " cfg;
in
{
  options.aliyss.androidPkgs = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = ''
      Android apps to install on the phone, by app-id from the
      aliyss-android-pkgs flake input (e.g. "com.darkempire78.opencalculator").
      Installed (built + pm-installed as root) on every home-manager switch;
      apps removed from the list are uninstalled. The install engine lives in
      aliyss-android-pkgs (scripts/install.sh, packages.android-install).
    '';
  };

  config = lib.mkIf isPhone {
    home.packages = [ installer ];

    # Runs on every switch (even with an empty list, to uninstall apps removed
    # since the last switch). After linkGeneration (home files) so the state
    # dir and the profile are in place. App-ids are safe for shell
    # interpolation (Android package names are [a-zA-Z0-9._]).
    home.activation.installAndroidPkgs = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      state_file="$HOME/.local/state/aliyss-android-pkgs"
      mkdir -p "$(dirname "$state_file")"

      log() { printf '\n\033[1;34m== %s ==\033[0m\n' "$*"; }
      warn() { printf '\033[1;33m!! %s\033[0m\n' "$*" >&2; }

      # Previous run's declared apps (for uninstall-on-removal).
      prev=""
      if [ -f "$state_file" ]; then
        prev="$(cat "$state_file")"
      fi
      curr="${appList}"

      # Uninstall apps that were declared before but are no longer.
      if [ -n "$prev" ]; then
        for id in $prev; do
          case " $curr " in
            *" $id "*) : ;;
            *)
              log "Uninstalling removed app: $id"
              android-install -d -f "$HOME/.config/flake" -u "$id" \
                || warn "could not uninstall $id (already gone?)"
              ;;
          esac
        done
      fi

      # Record what we manage before installing, so a failed install still
      # re-runs cleanly next time (no phantom uninstalls of already-gone apps).
      printf '%s\n' $curr >"$state_file"

      # Install (build + pm install as root) every declared app.
      if [ -n "$curr" ]; then
        log "Installing declared Android apps (aliyss.androidPkgs): ${lib.concatStringsSep ", " cfg}"
        if ! android-install -d -f "$HOME/.config/flake" $curr; then
          warn "one or more apps failed to install (Play Protect block? see above) — fix and re-run update-home"
          exit 1
        fi
      fi
    '';
  };
}
