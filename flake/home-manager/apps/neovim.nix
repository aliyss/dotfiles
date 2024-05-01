{pkgs, ...}: let
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
      pylint
      alejandra
    ];
    plugins = with plugins; [
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

      telescope-nvim
      neodev-nvim
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
