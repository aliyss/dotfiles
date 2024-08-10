{pkgs, ...}: let
  lolcrab =
    pkgs.rustPlatform.buildRustPackage
    rec {
      name = "lolcrab";
      pname = "lolcrab";

      src = pkgs.fetchFromGitHub {
        owner = "mazznoer";
        rev = "00c06cdd1089e3f9256a44e18f83667f76820fe1";
        repo = pname;
        sha256 = "1q40HQaM9ozv1v9QKdNCsJShyuP+tvV/YL+YEkN9/90=";
      };

      cargoLock = {
        lockFile = ./dependencies/lolcrab/Cargo.lock;
        outputHashes = {
          "colorgrad-0.7.0" = "sha256-FUoTeXQkMajZI+9VpoJNqDe/pjeUWXyQGiIr96uH6tg=";
          "csscolorparser-0.6.2" = "sha256-9HRS2Y+OJRYpzKMJ+ZdNHAHzuvDNMEcZZ4F+HAPpLhI=";
        };
      };
    };
  plugins = pkgs.vimPlugins // pkgs.callPackage ./neovim-plugins.nix {};
in {
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    extraPackages = with pkgs; [
      eslint_d
      ripgrep
      ripgrep-all
      tailwindcss
      luajitPackages.luacheck
      luajitPackages.lua-lsp
      luajitPackages.lua-curl
      xclip
      wl-clipboard
      stylua
      basedpyright
      pylint
      pylyzer
      postgresql_16
      black
      isort
      alejandra
      prettierd
      nodePackages_latest.jsonlint
      python311Packages.pynvim
      rust-analyzer
      lolcrab
      nil
    ];
    extraLuaPackages = pkgs: [
      pkgs.lua-curl
      pkgs.xml2lua
      pkgs.mimetypes
      pkgs.nvim-nio
    ];
    plugins = with plugins; [
      {
        plugin = nvim-tmux-navigation;
        config = builtins.readFile ./neovim/plugins/tmux-navigator.lua;
        type = "lua";
      }
      nvim-ts-context-commentstring
      todo-comments-nvim
      {
        plugin = comment-nvim;
        config = builtins.readFile ./neovim/plugins/comment.lua;
        type = "lua";
      }
      nvim-web-devicons
      # {
      #   plugin = dashboard-nvim;
      #   config = builtins.readFile ./neovim/plugins/dashboard.lua;
      #   type = "lua";
      # }
      plenary-nvim
      {
        plugin = harpoon;
        config = builtins.readFile ./neovim/plugins/harpoon.lua;
        type = "lua";
      }
      {
        plugin = neo-tree-nvim;
        config = builtins.readFile ./neovim/plugins/neo-tree.lua;
        type = "lua";
      }
      {
        plugin = project-nvim;
        config = builtins.readFile ./neovim/plugins/project.lua;
        type = "lua";
      }
      ## Treesitter
      nvim-ts-autotag
      nvim-treesitter.withAllGrammars
      ## SQL Grammar
      vim-dadbod
      vim-dadbod-ui
      vim-dadbod-completion
      ## Rest Client
      {
        plugin = rest-nvim;
        config = builtins.readFile ./neovim/plugins/modes/rest.lua;
        type = "lua";
      }
      ## OrgMode Grammar
      {
        plugin = orgmode;
        config = builtins.readFile ./neovim/plugins/modes/orgmode.lua;
        type = "lua";
      }
      ## CMP
      neodev-nvim
      cmp-buffer
      cmp-path
      cmp-nvim-lsp
      cmp_luasnip
      luasnip
      friendly-snippets
      lspkind-nvim
      {
        plugin = nvim-cmp;
        config = builtins.readFile ./neovim/plugins/cmp.lua;
        type = "lua";
      }
      ## Autopairs
      {
        plugin = nvim-autopairs;
        config = builtins.readFile ./neovim/plugins/autopairs.lua;
        type = "lua";
      }
      ## LSP
      mason-lspconfig-nvim
      mason-tool-installer-nvim
      {
        plugin = mason-nvim;
        config = builtins.readFile ./neovim/plugins/lsp/mason.lua;
        type = "lua";
      }
      {
        plugin = nvim-lspconfig;
        config = builtins.readFile ./neovim/plugins/lsp/lspconfig.lua;
        type = "lua";
      }
      ## Formatting
      guess-indent-nvim
      {
        plugin = conform-nvim;
        config = builtins.readFile ./neovim/plugins/lsp/formatting.lua;
        type = "lua";
      }
      ## Lint
      {
        plugin = nvim-lint;
        config = builtins.readFile ./neovim/plugins/lsp/linting.lua;
        type = "lua";
      }
      ## Highlighting
      {
        plugin = semshi;
        config = builtins.readFile ./neovim/plugins/lsp/highlighting.lua;
        type = "lua";
      }
      ## Errors
      {
        plugin = trouble;
        config = builtins.readFile ./neovim/plugins/trouble.lua;
        type = "lua";
      }
      ## Debugging
      direnv-vim
      {
        plugin = nvim-dap;
        config = builtins.readFile ./neovim/plugins/debugging/dap.lua;
        type = "lua";
      }
      nvim-nio
      {
        plugin = nvim-dap-ui;
        config = builtins.readFile ./neovim/plugins/debugging/dap-ui.lua;
        type = "lua";
      }
      ## Git
      {
        plugin = gitsigns-nvim;
        config = builtins.readFile ./neovim/plugins/git/gitsigns.lua;
        type = "lua";
      }
      ## LLM
      {
        plugin = copilot-vim;
        config = builtins.readFile ./neovim/plugins/llm/copilot.lua;
        type = "lua";
      }
      ## Telescope
      telescope-undo-nvim
      telescope-fzf-native-nvim
      {
        plugin = telescope-nvim;
        config = builtins.readFile ./neovim/plugins/telescope.lua;
        type = "lua";
      }
      ## Autosession
      {
        plugin = auto-session;
        config = builtins.readFile ./neovim/plugins/autosession.lua;
        type = "lua";
      }
      ## Themes
      {
        plugin = colorizer;
        config = builtins.readFile ./neovim/plugins/themes/colorizer.lua;
        type = "lua";
      }
      nyoom-oxocarbon
      {
        plugin = lualine-nvim;
        config = builtins.readFile ./neovim/plugins/themes/lualine.lua;
        type = "lua";
      }
      {
        plugin = ibl;
        config = builtins.readFile ./neovim/plugins/themes/ibl.lua;
        type = "lua";
      }
      ## Keybindings
      # {
      #   plugin = precognition;
      #   config = builtins.readFile ./neovim/plugins/keybindings/precognition.lua;
      #   type = "lua";
      # }
      {
        plugin = vim-be-good;
      }
      {
        plugin = hardtime-nvim;
        config = builtins.readFile ./neovim/plugins/keybindings/hardtime.lua;
        type = "lua";
      }
      {
        plugin = neoscroll-nvim;
        config = builtins.readFile ./neovim/plugins/keybindings/neoscroll.lua;
        type = "lua";
      }
      {
        plugin = which-key-nvim;
        config = builtins.readFile ./neovim/plugins/keybindings/which-key.lua;
        type = "lua";
      }
      {
        plugin = stay-in-place;
        config = builtins.readFile ./neovim/plugins/keybindings/stay-in-place.lua;
        type = "lua";
      }
      aw-watcher-vim
    ];
    extraLuaConfig = ''
      ${builtins.readFile ./neovim/options.lua}
      ${builtins.readFile ./neovim/colorscheme.lua}
    '';
  };
}
