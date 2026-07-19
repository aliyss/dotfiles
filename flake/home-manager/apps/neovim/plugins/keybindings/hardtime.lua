require("hardtime").setup({
	disabled_filetypes = { "NvimTree", "terminal", "neo-tree", "Trouble", "Telescope" },
	disabled_keys = {
		["<Up>"] = false,
		["<Down>"] = false,
	},
	disable_mouse = true,
	max_count = 5,
})
