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
  trouble = pkgs.vimUtils.buildVimPlugin {
    name = "trouble";
    src = pkgs.fetchgit {
      url = "https://github.com/folke/trouble.nvim";
      rev = "b4b9a11b3578d510963f6f681fecb4631ae992c3";
      sha256 = "sha256-TjQ8UiV1BqmAddhu9iu+X1HbmCS6SQoIOyXbe8gZRqo=";
    };
  };
  nvim-tmux-navigation = pkgs.vimUtils.buildVimPlugin {
    name = "nvim-tmux-navigation";
    src = pkgs.fetchgit {
      url = "https://github.com/alexghergh/nvim-tmux-navigation";
      rev = "4898c98702954439233fdaf764c39636681e2861";
      sha256 = "sha256-CxAgQSbOrg/SsQXupwCv8cyZXIB7tkWO+Y6FDtoR8xk=";
    };
  };
}
