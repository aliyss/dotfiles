{
  # ─── Neovim theme highlighter generator ──────────────────────────
  # Produces a Lua snippet that sets highlight groups from the theme.
  #
  # Usage:
  #   neovimHighlights theme
  #   → string of Lua that you inline into initLua or a plugin config

  theme,
  ...
}: let
  s = theme.semantic;
  p = theme.palette;
  n = s.neovimMarkviewHeading1;
in ''
  -- ██  Generated from flake/lib/theme.nix  ██
  -- ██  Do not edit directly – change theme.nix and rebuild  ██

  do
    local a = vim.api

    -- Markview headings
    a.nvim_set_hl(0, "MarkviewHeading1",        { bg = "${s.neovimMarkviewHeading1.bg}", fg = "${s.neovimMarkviewHeading1.fg}" })
    a.nvim_set_hl(0, "MarkviewHeading1Sign",    { fg = "${s.neovimMarkviewHeading1.fg}" })
    a.nvim_set_hl(0, "MarkviewHeading1Label",   { fg = "${s.neovimMarkviewHeading1.fg}" })
    a.nvim_set_hl(0, "MarkviewHeading2",        { bg = "${s.neovimMarkviewHeading2.bg}", fg = "${s.neovimMarkviewHeading2.fg}" })
    a.nvim_set_hl(0, "MarkviewHeading2Sign",    { fg = "${s.neovimMarkviewHeading2.fg}" })
    a.nvim_set_hl(0, "MarkviewHeading2Label",   { fg = "${s.neovimMarkviewHeading2.fg}" })
    a.nvim_set_hl(0, "MarkviewHeading3",        { bg = "${s.neovimMarkviewHeading3.bg}", fg = "${s.neovimMarkviewHeading3.fg}" })
    a.nvim_set_hl(0, "MarkviewHeading3Label",   { fg = "${s.neovimMarkviewHeading3.fg}" })
    a.nvim_set_hl(0, "MarkviewHeading4",        { bg = "${s.neovimMarkviewHeading4.bg}", fg = "${s.neovimMarkviewHeading4.fg}" })
    a.nvim_set_hl(0, "MarkviewHeading4Label",   { fg = "${s.neovimMarkviewHeading4.fg}" })
    a.nvim_set_hl(0, "MarkviewHeading5",        { bg = "${s.neovimMarkviewHeading5.bg}", fg = "${s.neovimMarkviewHeading5.fg}" })
    a.nvim_set_hl(0, "MarkviewHeading5Label",   { fg = "${s.neovimMarkviewHeading5.fg}" })
    a.nvim_set_hl(0, "MarkviewHeading6",        { bg = "${s.neovimMarkviewHeading6.bg}", fg = "${s.neovimMarkviewHeading6.fg}" })
    a.nvim_set_hl(0, "MarkviewHeading6Label",   { fg = "${s.neovimMarkviewHeading6.fg}" })

    -- LSP inlay hints
    a.nvim_set_hl(0, "LspInlayHint",            { fg = "${s.neovimLspInlayHint}" })

    -- Transparent background
    a.nvim_set_hl(0, "Normal",                  { bg = "none" })
    a.nvim_set_hl(0, "NormalNC",                { bg = "none" })
    a.nvim_set_hl(0, "NormalFloat",             { bg = "none" })
    a.nvim_set_hl(0, "LineNr",                  { bg = "none" })
    a.nvim_set_hl(0, "SignColumn",              { bg = "none" })
    a.nvim_set_hl(0, "TelescopeNormal",         { bg = "none" })
  end
''
