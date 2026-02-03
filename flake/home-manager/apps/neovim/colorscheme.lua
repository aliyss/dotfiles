local c = vim.cmd
local a = vim.api

c.colorscheme("tokyonight")

a.nvim_set_hl(0, "Normal", { bg = "none" })
a.nvim_set_hl(0, "NormalNC", { bg = "none" })
a.nvim_set_hl(0, "NormalFloat", { bg = "none" })
a.nvim_set_hl(0, "LineNr", { bg = "none" })
a.nvim_set_hl(0, "SignColumn", { bg = "none" })

-- Telescope
a.nvim_set_hl(0, "TelescopeNormal", { bg = "none" })
a.nvim_set_hl(0, "LspInlayHint", { fg = "#666666" })

a.nvim_set_hl(0, "MarkviewHeading1", { bg = "#453244", fg = "#f38ba8" })
a.nvim_set_hl(0, "MarkviewHeading1Sign", { fg = "#f38ba8" })
a.nvim_set_hl(0, "MarkviewHeading1Label", { fg = "#f38ba8" })
a.nvim_set_hl(0, "MarkviewHeading2", { bg = "#46393E", fg = "#fab387" })
a.nvim_set_hl(0, "MarkviewHeading2Sign", { fg = "#fab387" })
a.nvim_set_hl(0, "MarkviewHeading2Label", { fg = "#fab387" })
a.nvim_set_hl(0, "MarkviewHeading3", { bg = "#464245", fg = "#f9e2af" })
a.nvim_set_hl(0, "MarkviewHeading3Label", { fg = "#f9e2af" })
a.nvim_set_hl(0, "MarkviewHeading4", { bg = "#374243", fg = "#a6e3a1" })
a.nvim_set_hl(0, "MarkviewHeading4Label", { fg = "#a6e3a1" })
a.nvim_set_hl(0, "MarkviewHeading5", { bg = "#2E3D51", fg = "#74c7ec" })
a.nvim_set_hl(0, "MarkviewHeading5Label", { fg = "#74c7ec" })
a.nvim_set_hl(0, "MarkviewHeading6", { bg = "#393B54", fg = "#b4befe" })
a.nvim_set_hl(0, "MarkviewHeading6Label", { fg = "#b4befe" })
