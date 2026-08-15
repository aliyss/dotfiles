{
  config,
  lib,
  ...
}:
# Declarative Android app installs on the phone (aliyss.androidPkgs).
#
# Apps come from the aliyss-android-pkgs flake input, which flake/flake.nix
# re-exports as flake.packages.<system> — so every pinned app-id is a buildable
# derivation on the phone. Declare the app-ids you want installed and every
# `home-manager switch` builds + pm-installs them:
#
#   aliyss.androidPkgs = [
#     "com.darkempire78.opencalculator"
#     "org.videolan.vlc"
#   ];
#
# The install engine is the same script the manual `install-app` alias runs
# (aliyss-phone/install-app.sh — the single source of truth, referenced from
# the repo checkout at runtime, since the flake root cannot see repo-root
# files): it maps the chroot store path to the host-visible
# ~/.nix/nix/store, installs as root (su -c 'pm install -r'), and bounds the
# install at 60s so a Google Play Protect block is reported instead of hanging
# the switch. A failed install fails the switch loudly (fix it — e.g. allow
# the app in Play Protect — and re-run update-home).
#
# Phone-only: this module is imported only by flake/hosts/termux/home.nix.
let
  isPhone = config.aliyss.isPhone;
  cfg = config.aliyss.androidPkgs;
in
{
  options.aliyss.androidPkgs = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = ''
      Android apps to install on the phone, by app-id from the
      aliyss-android-pkgs flake input (e.g. "com.darkempire78.opencalculator").
      Built and pm-installed (as root) on every home-manager switch.
    '';
  };

  config = lib.mkIf (isPhone && cfg != [ ]) {
    # After linkGeneration (home files) so the checkout the install script
    # lives in is already in place. App-ids are safe for shell interpolation
    # (Android package names are [a-zA-Z0-9._]).
    home.activation.installAndroidPkgs = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      log() { printf '\n\033[1;34m== %s ==\033[0m\n' "$*"; }
      log "Installing declared Android apps (aliyss.androidPkgs): ${lib.concatStringsSep ", " cfg}"
      if ! bash "$HOME/.config/aliyss-phone/install-app.sh" ${lib.concatStringsSep " " cfg}; then
        echo "  !! one or more apps failed to install (Play Protect block? see above) — fix and re-run update-home" >&2
        exit 1
      fi
    '';
  };
}
