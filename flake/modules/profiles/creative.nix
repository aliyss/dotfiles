{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.aliyss.profiles;
  eciIcc = pkgs.callPackage ../../packages/eci-icc-profiles { };
in
mkIf cfg.creative {
  # ECI + Adobe ICC profiles for HGK PDF/X workflow
  # Provides: ISOcoated_v2_300_eci.icc (HGK Standard), PSOcoated_v3 (FOGRA51),
  # PSOuncoated_v3_FOGRA52, eciRGB_v2, AdobeRGB1998, etc.
  # Sources: https://www.eci.org/doku.php?id=en:downloads#icc_profiles_from_eci
  environment.systemPackages = [ eciIcc ];

  # Make profiles available system-wide via standard XDG / colord paths.
  # NixOS symlinks /run/current-system/sw/share/* via environment.pathsToLink.
  environment.pathsToLink = [ "/share/color" ];

  # colord daemon for ICC management (optional but recommended on Linux).
  # Exposes profiles to apps via DBus and allows GNOME/KDE color settings to see them.
  services.colord.enable = true;

  # Also expose via legacy /etc/color/icc for apps that hardcode Adobe paths
  # (Linux equivalent of /Library/Application Support/Adobe/Color/Profiles/Recommended
  #  and C:\Windows\System32\spool\drivers\color on Windows/macOS).
  environment.etc."color/icc".source = "${eciIcc}/share/color/icc";

  # Provide XDG data dirs hint for apps that look in /usr/share/color/icc
  environment.sessionVariables = {
    XDG_DATA_DIRS = [ "${eciIcc}/share" ];
  };

  # Ensure fontconfig doesn't interfere (profiles are not fonts, but keep for completeness)
  fonts.fontconfig.enable = true;
}
