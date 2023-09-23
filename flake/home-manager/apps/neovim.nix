{ pkgs, ... }:

{
  programs.neovim = let
    toLua = str: ''
      lua << EOF
      ${str}
      EOF
    '';
    toLuaFile = file: ''
      lua << EOF
      ${builtins.readFile file}
      EOF
    '';
  in {
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
        config = toLua ''require("Comment").setup()'';
      }
      {
        plugin = nvim-cmp;
        config = toLuaFile ./neovim/plugin/cmp.lua;
      }
      {
        plugin = nvim-lspconfig;
        config = toLuaFile ./neovim/plugin/lsp.lua;
      }
      telescope-nvim
      dashboard-nvim
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
