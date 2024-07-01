{
  lib,
  stdenv,
  fetchzip,
  rustPlatform,
  ...
}: let
  inherit (stdenv.hostPlatform) system;
  throwSystem = throw "Unsupported system: ${system}";

  sha256 =
    {
      x86_64-linux = "sha256-6oYZY1Ry4U/nR99DNsr7ZqTd/AAot+yrOHY75UXEuWY=";
      aarch64-linux = "sha256-/XAv/ptvUsWLF/iIOiqm/PoCLhVTL3Cnmd0YdqLBthk=";
      armv7l-linux = "sha256-CbtzY2q7HnqCcolTFyTphWbHN/VdSt/rs8q3tjHHNqc=";
    }
    .${system}
    or throwSystem;
in
  rustPlatform.buildRustPackage rec {
    pname = "awatcher";
    version = "0.2.7";

    buildInputs = [
    ];

    nativeBuildInputs = [
    ];

    src = fetchzip {
      url = "https://github.com/2e3s/${pname}/archive/refs/tags/v${version}.tar.gz";
      stripRoot = false;
      inherit sha256;
    };

    cargoHash = "";
    cargoLock = {
      lockFile = ./Cargo.lock;
      allowBuiltinFetchGit = true;
    };
    cargoPatches = [
      ./Cargo.lock
    ];

    meta = with lib; {
      description = "Activity and idle watchers";
      homepage = "https://github.com/2e3s/awatcher";
      license = licenses.unlicense;
      maintainers = [];
    };
  }
