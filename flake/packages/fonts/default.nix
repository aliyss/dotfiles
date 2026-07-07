{ pkgs, lib, ... }:
pkgs.stdenv.mkDerivation {
  pname = "local-fonts";
  version = "1.0.0";
  src = ./.;
  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/share/fonts/{truetype,opentype}
    find $src -maxdepth 1 -name '*.ttf' -exec cp -t $out/share/fonts/truetype {} \;
    find $src -maxdepth 1 -name '*.otf' -exec cp -t $out/share/fonts/opentype {} \;
  '';
  meta = with lib; {
    description = "Local fonts: Milky Way, Kenoky, Magilio, Nighty";
    platforms = lib.platforms.all;
  };
}
