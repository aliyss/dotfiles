-- ██  Base colorscheme init  ██
-- ██  Theme-driven highlights are injected by flake/lib/themes/neovim.nix  ██

vim.cmd.colorscheme("oxocarbon")

for _, grp in ipairs({ "Normal", "NormalNC", "NormalFloat", "LineNr", "SignColumn", "TelescopeNormal" }) do
  vim.api.nvim_set_hl(0, grp, { bg = "none" })
end
