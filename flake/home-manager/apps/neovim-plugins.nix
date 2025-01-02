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
      sha256 = "sha256-Hi/nATEvZ4a6Yxc66KtuJqss6kQV19cmtIlhCw6alOI=";
    };
  };
  # harpoon = pkgs.vimUtils.buildVimPlugin {
  #   name = "harpoon";
  #   src = pkgs.fetchgit {
  #     url = "https://github.com/ThePrimeagen/harpoon";
  #     rev = "0378a6c428a0bed6a2781d459d7943843f374bce";
  #     sha256 = "sha256-FZQH38E02HuRPIPAog/nWM55FuBxKp8AyrEldFkoLYk=";
  #   };
  # };
  trouble = pkgs.vimUtils.buildVimPlugin {
    name = "trouble";
    src = pkgs.fetchgit {
      url = "https://github.com/folke/trouble.nvim";
      rev = "46cf952fc115f4c2b98d4e208ed1e2dce08c9bf6";
      sha256 = "sha256-JhnERZfma2JHFEn/DElVmrSU5KxM2asx3SJ+86lCfoo=";
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
  # ibl = pkgs.vimUtils.buildVimPlugin {
  #   name = "ibl";
  #   src = pkgs.fetchgit {
  #     url = "https://github.com/lukas-reineke/indent-blankline.nvim";
  #     rev = "259357fa4097e232730341fa60988087d189193a";
  #     sha256 = "sha256-H3lUQZDvgj3a2STYeMUDiOYPe7rfsy08tJ4SlDd+LuE=";
  #   };
  # };
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
      rev = "545509268d5e928d72d64764c21ef65c77e90edf";
      sha256 = "sha256-bhyiGb4P+eG5FroQafhuVIxnnrM1ZJOIBy7O2bwnrpU=";
    };
  };
  # blade-nav = pkgs.vimUtils.buildVimPlugin {
  #   name = "blade-nav";
  #   src = pkgs.fetchgit {
  #     url = "https://github.com/RicardoRamirezR/blade-nav.nvim";
  #     rev = "fbf82a609572b568399740e24ccb23d5c7fefe5d";
  #     sha256 = "sha256-RjUa5XYDr6hgCuxIixVNA4AtjgdOdI03xBHIbHyUoMg=";
  #   };
  # };
  notmuch-vim = pkgs.vimUtils.buildVimPlugin {
    name = "notmuch-vim";
    src = pkgs.fetchgit {
      url = "https://github.com/felipec/notmuch-vim";
      rev = "4270c7e4d4ee1e7f044baedfe087bb33551dee7c";
      sha256 = "sha256-GzXHs+SkmLHknLknykgs7aGsZF+No1u5Jc4hwzzeMP4=";
    };
  };
  himalaya-custom-vim = pkgs.vimUtils.buildVimPlugin {
    name = "himalaya-custom-vim";
    src = pkgs.fetchgit {
      url = "https://github.com/pimalaya/himalaya-vim";
      rev = "f25c003e8fe532348b4080bf8d738cfa1bbf1f5f";
      sha256 = "sha256-oQtl3VmLpZf+cj1YGLKHbxmaE5GFLEeDi2Z7g3mvZjc=";
    };
  };
  pckr-nvim = pkgs.vimUtils.buildVimPlugin {
    name = "pckr-nvim";
    src = pkgs.fetchgit {
      url = "https://github.com/lewis6991/pckr.nvim";
      rev = "b84aad12570471b1a64d280ad060c59e168dc950";
      sha256 = "sha256-K9CtVKr+AkZP+wrWsUWaCRrlgN28NXw0Oyc6o4A1zM4=";
    };
  };
}
