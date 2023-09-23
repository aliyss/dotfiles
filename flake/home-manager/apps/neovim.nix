{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    extraPackages = with pkgs; [
      luajitPackages.lua-lsp
      rnix-lsp

      xclip
      wl-clipboard
    ];
    plugins = with pkgs.vimPlugins; [
      {
        plugin = comment-nvim;
        config = ''require("Comment").setup()'';
        type = "lua";
      }
      {
        plugin = nvim-cmp;
        config = builtins.readFile ./neovim/plugin/cmp.lua;
        type = "lua";
      }
      {
        plugin = nvim-lspconfig;
        config = builtins.readFile ./neovim/plugin/lsp.lua;
        type = "lua";
      }
      {
        plugin = dashboard-nvim;
        config = builtins.readFile ./neovim/plugin/dashboard.lua;
        type = "lua";
      }
      telescope-nvim
      which-key-nvim
      cmp_luasnip
      cmp-nvim-lsp
      luasnip
      neodev-nvim
    ];
    extraLuaConfig = ''
      ${builtins.readFile ./neovim/options.lua}
    '';
  };
}
