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
      luajitPackages.luacheck
      luajitPackages.lua-lsp
      xclip
      wl-clipboard
      stylua
      pyright
      black
      isort
      alejandra
      lolcrab
    ];
    plugins = with plugins; [
      {
        plugin = nvim-tmux-navigation;
        config = builtins.readFile ./neovim/plugin/tmux-navigator.lua;
        type = "lua";
      }
      nvim-ts-context-commentstring
      todo-comments-nvim
      {
        plugin = comment-nvim;
        config = builtins.readFile ./neovim/plugin/comment.lua;
        type = "lua";
      }
      nvim-web-devicons
      {
        plugin = dashboard-nvim;
        config = builtins.readFile ./neovim/plugin/dashboard.lua;
        type = "lua";
      }
      plenary-nvim
      {
        plugin = harpoon;
        config = builtins.readFile ./neovim/plugin/harpoon.lua;
        type = "lua";
      }
      {
        plugin = neo-tree-nvim;
        config = builtins.readFile ./neovim/plugin/neo-tree.lua;
        type = "lua";
      }
      {
        plugin = project-nvim;
        config = builtins.readFile ./neovim/plugin/project.lua;
        type = "lua";
      }

      ## Treesitter
      nvim-ts-autotag
      nvim-treesitter.withAllGrammars
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
        config = builtins.readFile ./neovim/plugin/cmp.lua;
        type = "lua";
      }
      ## Autopairs
      {
        plugin = nvim-autopairs;
        config = builtins.readFile ./neovim/plugin/autopairs.lua;
        type = "lua";
      }
      ## LSP
      mason-lspconfig-nvim
      mason-tool-installer-nvim
      {
        plugin = mason-nvim;
        config = builtins.readFile ./neovim/plugin/lsp/mason.lua;
        type = "lua";
      }
      {
        plugin = nvim-lspconfig;
        config = builtins.readFile ./neovim/plugin/lsp/lspconfig.lua;
        type = "lua";
      }
      ## Formatting
      {
        plugin = conform-nvim;
        config = builtins.readFile ./neovim/plugin/formatting.lua;
        type = "lua";
      }
      ## Lint
      {
        plugin = nvim-lint;
        config = builtins.readFile ./neovim/plugin/linting.lua;
        type = "lua";
      }
      ## Errors
      {
        plugin = trouble;
        config = builtins.readFile ./neovim/plugin/trouble.lua;
        type = "lua";
      }
      ## Debugging
      {
        plugin = nvim-dap;
        config = builtins.readFile ./neovim/plugin/dap.lua;
        type = "lua";
      }
      nvim-nio
      {
        plugin = nvim-dap-ui;
        config = builtins.readFile ./neovim/plugin/dap-ui.lua;
        type = "lua";
      }
      telescope-nvim
      ## Themes
      nyoom-oxocarbon
      {
        plugin = lualine-nvim;
        config = builtins.readFile ./neovim/theme/lualine.lua;
        type = "lua";
      }
      ## Keybindings
      {
        plugin = which-key-nvim;
        config = builtins.readFile ./neovim/plugin/which-key.lua;
        type = "lua";
      }
    ];
    extraLuaConfig = ''
      ${builtins.readFile ./neovim/options.lua}
      ${builtins.readFile ./neovim/colorscheme.lua}
    '';
  };
}
