{ config, lib, pkgs, ... }:
let
  localFonts = pkgs.callPackage ../../packages/fonts { };
  cfg = config.aliyss.adobeFonts;
  # FOD – fetches https://use.typekit.net/<kitId>.css at build (license: not vendored)
  adobeFonts = pkgs.callPackage ../../packages/adobe-fonts { };
in {
  fonts.packages = with pkgs; [
    localFonts
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
  ] ++ lib.optionals cfg.enable [ adobeFonts ];

  # Help debugging: expose kit ID in system
  environment.sessionVariables = lib.mkIf cfg.enable {
    ADOBE_FONTS_KIT = cfg.kitId;
  };
}
