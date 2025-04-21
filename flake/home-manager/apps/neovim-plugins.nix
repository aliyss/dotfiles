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
  pipeline-nvim = pkgs.vimUtils.buildVimPlugin {
    name = "pipeline-nvim";
    src = pkgs.fetchgit {
      url = "https://github.com/topaxi/pipeline.nvim";
      rev = "805d918b0ff0811611a40eaa7a662600900044e8";
      sha256 = "sha256-R360qmXENRguzDzP3I7+vMRZ6aCeJm5YcdV51WfRDOQ=";
    };
  };
  incline-nvim = pkgs.vimUtils.buildVimPlugin {
    name = "incline-nvim";
    src = pkgs.fetchgit {
      url = "https://github.com/b0o/incline.nvim";
      rev = "16fc9c073e3ea4175b66ad94375df6d73fc114c0";
      sha256 = "sha256-5DoIvIdAZV7ZgmQO2XmbM3G+nNn4tAumsShoN3rDGrs=";
    };
  };
  vim-bufsurf = pkgs.vimUtils.buildVimPlugin {
    name = "vim-bufsurf";
    src = pkgs.fetchgit {
      url = "https://github.com/ton/vim-bufsurf";
      rev = "e6dbc7ad66c7e436e5eb20d304464e378bd7f28c";
      sha256 = "sha256-o/Uf4bnh3IctKnT50JitTe5/+BUrCyrlOOzkmwAzxLk=";
    };
  };
  modes-nvim = pkgs.vimUtils.buildVimPlugin {
    name = "modes-nvim";
    src = pkgs.fetchgit {
      url = "https://github.com/mvllow/modes.nvim";
      rev = "1e34663c32e8f5d915921a938e0dc4e3e788ceb8";
      sha256 = "sha256-XgER+qp/GSAimj7C23coOpwsEc3CdImyN+tFVIPKqh0=";
    };
  };
  llama-vim = pkgs.vimUtils.buildVimPlugin {
    name = "llama-vim";
    src = pkgs.fetchgit {
      url = "https://github.com/ggml-org/llama.vim";
      rev = "9cf5ed33b28edd7b2c7925677ef15c7779f054de";
      sha256 = "sha256-+x29Ma1N4tNBcCOGTox4XucFFMQzFqgEo03APajoa/Q=";
    };
  };
  augment-vim = pkgs.vimUtils.buildVimPlugin {
    name = "augment-vim";
    src = pkgs.fetchgit {
      url = "https://github.com/augmentcode/augment.vim";
      rev = "a50e362f6c16a0c43da20f613e337a6dfd3fb94a";
      sha256 = "sha256-+TbnXjAEugCCpoi4axbPhbTeSGAwASj/MLzzI2N0NtQ=";
    };
  };
  gopher-nvim = pkgs.vimUtils.buildVimPlugin {
    name = "gopher-nvim";
    dependencies = with pkgs.vimPlugins; [
      plenary-nvim
      nvim-treesitter
      nvim-dap
    ];
    src = pkgs.fetchgit {
      url = "https://github.com/olexsmir/gopher.nvim";
      rev = "0ed14a40d9799ac8d92aaf9eb1cd9be22ffd6b14";
      sha256 = "sha256-5UpNPRh4YdAtpiFTazqCSLeJ0TMmPCm8lVyNFsIJ3lE=";
    };
  };
}
