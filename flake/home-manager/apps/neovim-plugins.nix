{pkgs, ...}: {
  nyoom = pkgs.vimUtils.buildVimPlugin {
    name = "nyoom";
    src = pkgs.fetchgit {
      url = "https://github.com/nyoom-engineering/nyoom.nvim";
      sha256 = "sha256-XzQB4bZeS2xTCEsUvPNi66901ZSI1k576oEFjTA54nU=";
    };
  };
  nyoom-oxocarbon = pkgs.vimUtils.buildVimPlugin {
    name = "nyoom-oxocarbon";
    src = pkgs.fetchgit {
      url = "https://github.com/nyoom-engineering/oxocarbon.nvim";
      sha256 = "sha256-++JALLPklok9VY2ChOddTYDvDNVadmCeB98jCAJYCZ0=";
    };
  };
  harpoon = pkgs.vimUtils.buildVimPlugin {
    name = "harpoon";
    src = pkgs.fetchgit {
      url = "https://github.com/ThePrimeagen/harpoon";
      rev = "0378a6c428a0bed6a2781d459d7943843f374bce";
      sha256 = "sha256-FZQH38E02HuRPIPAog/nWM55FuBxKp8AyrEldFkoLYk=";
    };
  };
}
