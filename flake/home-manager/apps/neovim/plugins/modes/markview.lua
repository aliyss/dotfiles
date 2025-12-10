local presets = require("markview.presets")

require("markview").setup({
	preview = {
		enable = true,
		enable_hybrid_mode = true,
		-- linewise_hybrid_mode = true,
		hybrid_modes = { "n" },
	},
	markdown = {
		headings = presets.headings.glow,
	},
})

vim.g.markview_blink_loaded = true;
