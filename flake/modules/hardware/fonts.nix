{ pkgs, ... }:
let
  localFonts = pkgs.callPackage ../../packages/fonts { };
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
  ];
}
