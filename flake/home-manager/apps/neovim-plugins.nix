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
  ibl = pkgs.vimUtils.buildVimPlugin {
    name = "ibl";
    src = pkgs.fetchgit {
      url = "https://github.com/lukas-reineke/indent-blankline.nvim";
      rev = "3d08501caef2329aba5121b753e903904088f7e6";
      sha256 = "sha256-Xp8ZQBz0in2MX3l0bnLUsSbH0lDPE+QvdmFpBFry5yY=";
    };
  };
  precognition = pkgs.vimUtils.buildVimPlugin {
    name = "precognition";
    src = pkgs.fetchgit {
      url = "https://github.com/tris203/precognition.nvim";
      rev = "455f5275649990f99449ac152a832dc7a9b42a6a";
      sha256 = "sha256-hzaY0OE0i4nMcU0E7LYm6+IAwoGYt1Xxx4H7nhssCdM=";
    };
  };
  aw-watcher-vim = pkgs.vimUtils.buildVimPlugin {
    name = "aw-watcher-vim";
    src = pkgs.fetchgit {
      url = "https://github.com/ActivityWatch/aw-watcher-vim";
      rev = "4ba86d05a940574000c33f280fd7f6eccc284331";
      sha256 = "sha256-I7YYvQupeQxWr2HEpvba5n91+jYvJrcWZhQg+5rI908=";
    };
  };
  stay-in-place = pkgs.vimUtils.buildVimPlugin {
    name = "stay-in-place";
    src = pkgs.fetchgit {
      url = "https://github.com/gbprod/stay-in-place.nvim";
      rev = "0628b6db8970fc731abf9608d6f80659b58932c9";
      sha256 = "sha256-Cq9/JQoxuUiAQPobiSizwmvdxJRjE7XjG47A38wdVwY=";
    };
  };
  wookayin-semshi = pkgs.vimUtils.buildVimPlugin {
    name = "wookayin-semshi";
    src = pkgs.fetchgit {
      url = "https://github.com/wookayin/semshi";
      rev = "0182447e2ff4dfa04cd2dfe5f189e012c581ca45";
      sha256 = "sha256-gQy8rQBTzODp8OfnHdggxSq275/9T8feJAkWzH+CdvU=";
    };
  };
  git-rest-nvim = pkgs.vimUtils.buildVimPlugin {
    name = "rest-nvim";
    src = pkgs.fetchgit {
      url = "https://github.com/rest-nvim/rest.nvim";
      rev = "e7843c55f9df6a9db9f97dac180035c6ff895a90";
      sha256 = "sha256-bVm50Z4cNm+TKOZzY8i+3+8X9yqJ5Bd6/AP5qrrUMwo=";
    };
  };
  blade-nav = pkgs.vimUtils.buildVimPlugin {
    name = "blade-nav";
    src = pkgs.fetchgit {
      url = "https://github.com/RicardoRamirezR/blade-nav.nvim";
      rev = "fbf82a609572b568399740e24ccb23d5c7fefe5d";
      sha256 = "sha256-RjUa5XYDr6hgCuxIixVNA4AtjgdOdI03xBHIbHyUoMg=";
    };
  };
}
