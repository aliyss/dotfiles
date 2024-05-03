{pkgs, ...}: {
  name = "lolcrab";
  pname = "lolcrab";

  src = pkgs.fetchFromGitHub {
    owner = "mazznoer";
    rev = "00c06cdd1089e3f9256a44e18f83667f76820fe1";
    repo = "lolcrab";
    sha256 = "1q40HQaM9ozv1v9QKdNCsJShyuP+tvV/YL+YEkN9/90=";
  };

  cargoLock = {
    lockFile = ./dependencies/lolcrab/Cargo.lock;
    outputHashes = {
      "colorgrad-0.7.0" = "sha256-FUoTeXQkMajZI+9VpoJNqDe/pjeUWXyQGiIr96uH6tg=";
      "csscolorparser-0.6.2" = "sha256-9HRS2Y+OJRYpzKMJ+ZdNHAHzuvDNMEcZZ4F+HAPpLhI=";
    };
  };
}
