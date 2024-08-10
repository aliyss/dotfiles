local c = vim.cmd
local a = vim.api

c.colorscheme("oxocarbon")

a.nvim_set_hl(0, "Normal", { bg = "none" })
a.nvim_set_hl(0, "NormalNC", { bg = "none" })
a.nvim_set_hl(0, "NormalFloat", { bg = "none" })
a.nvim_set_hl(0, "LineNr", { bg = "none" })
a.nvim_set_hl(0, "SignColumn", { bg = "none" })

-- Telescope
a.nvim_set_hl(0, "TelescopeNormal", { bg = "none" })
a.nvim_set_hl(0, "LspInlayHint", { fg = "#666666" })
