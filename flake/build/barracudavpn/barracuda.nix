{
  stdenv,
  lib,
  dpkg,
}:
# Omg thanks to Rik Bastiaens for the original Nix expression
# https://github.com/rawtbastiaens/nix/blob/main/build/barracudavpn/barracuda.nix
# https://www.youtube.com/watch?v=CqFcl4BmbN4
stdenv.mkDerivation rec {
  name = "barracudavpn-${version}";
  deb = "barracudavpn_${version}_amd64.deb";
  version = "5.3.6";
  src = ./.;

  buildInputs = [dpkg];

  installPhase = ''
    mkdir -p $out/bin
    dpkg-deb --fsys-tarfile $deb | \
      tar -x --no-same-owner
    mv usr/local/bin/barracudavpn $out/bin
    rm -r usr
  '';

  meta = with lib; {
    description = "Barracuda VPN Client 5.3.6 for Linux";
    homepage = https://dlportal.barracudanetworks.com/;
    license = licenses.mit;
    maintainers = with stdenv.lib.maintainers; [];
    platforms = ["x86_64-linux"];
  };
}
