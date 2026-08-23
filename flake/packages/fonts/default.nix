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
    find $src -maxdepth 1 -name '*.woff' -exec cp -t $out/share/fonts/truetype {} \;
    find $src -maxdepth 1 -name '*.woff2' -exec cp -t $out/share/fonts/truetype {} \;
  '';
  meta = with lib; {
    description = "Local fonts: Milky Way, Kenoky, Magilio, Nighty, Artica (Medium/Bold), TheSerif SemiBold, SkySerif Semibold";
    platforms = lib.platforms.all;
  };
}
