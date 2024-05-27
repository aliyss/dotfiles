local signs = { error = " ", warning = " ", hint = "󰘥 ", information = " " }

require("trouble").setup({
	auto_close = true,
	focus = true,
	auto_preview = true,
	signs = signs,
	keys = {
		["<cr>"] = "jump_close",
		o = "close",
	},
})
