{ config, lib, pkgs, ... }:
with lib; let
  cfg = config.aliyss.profiles;
  eciIcc = pkgs.callPackage ../../packages/eci-icc-profiles { };
in
mkIf cfg.creative {
  # User-local ICC directory (XDG spec: ~/.local/share/color/icc)
  # Home Manager will symlink every .icc from the package there.
  # This is the Linux equivalent of macOS ~/Library/ColorSync/Profiles
  # and Windows C:\Windows\System32\spool\drivers\color for native Linux apps
  # (Scribus, GIMP, Krita, Inkscape, Darktable, colord).
  home.file.".local/share/color/icc" = {
    source = "${eciIcc}/share/color/icc";
    recursive = true;
  };

  # Affinity on Linux runs under Wine (affinity-nix). Wine looks for ICCs in
  # drive_c/windows/system32/spool/drivers/color  and
  # drive_c/windows/system32/color . Affinity also bundles some ICCs under
  # Program Files/Affinity/Resources/ICC but respects system profiles.
  # We use a home activation to copy/symlink profiles into the Wine prefix
  # after home-manager switch, covering both affinity-v3 and legacy v2 prefixes.
  home.activation.eciIccWine = lib.hm.dag.entryAfter ["writeBoundary"] ''
    set -euo pipefail
    ICC_SRC="${eciIcc}/share/color/icc"
    for prefix in "$HOME/.local/share/affinity" "$HOME/.local/share/affinity-v3" "$HOME/.wine"; do
      if [ -d "$prefix" ]; then
        for dest in \
          "$prefix/drive_c/windows/system32/spool/drivers/color" \
          "$prefix/drive_c/windows/system32/color" \
          "$prefix/drive_c/Program Files/Affinity/Affinity/Resources/ICC" \
          "$prefix/drive_c/Program Files/Affinity Photo/Resources/ICC" \
        ; do
          mkdir -p "$dest"
          # symlink each ICC (force, no clobber of user custom profiles)
          for icc in "$ICC_SRC"/*.icc "$ICC_SRC"/*.icm; do
            [ -f "$icc" ] || continue
            base=$(basename "$icc")
            if [ ! -e "$dest/$base" ]; then
              ln -sf "$icc" "$dest/$base" 2>/dev/null || cp -n "$icc" "$dest/$base" 2>/dev/null || true
            fi
          done
        done
        echo "eci-icc: synced to Wine prefix $prefix"
      fi
    done

    # Also ensure the native Linux colord/XDG path is populated (home.file
    # already handles ~/.local/share/color/icc, but ensure the directory exists
    # for apps that run before HM activation finishes).
    mkdir -p "$HOME/.local/share/color/icc"
    # Verify key HGK profiles are present
    for needed in ISOcoated_v2_300_eci.icc PSOcoated_v3.icc PSOuncoated_v3_FOGRA52.icc AdobeRGB1998.icc eciRGB_v2.icc; do
      if [ ! -f "$HOME/.local/share/color/icc/$needed" ]; then
        echo "warn: $needed missing in ~/.local/share/color/icc" >&2
      fi
    done
  '';
}
