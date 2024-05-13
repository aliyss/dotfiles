local signs = { error = " ", warning = " ", hint = "󰘥 ", information = " " }

require("trouble").setup({
	focus = true,
	auto_preview = true,
	signs = signs,
})
