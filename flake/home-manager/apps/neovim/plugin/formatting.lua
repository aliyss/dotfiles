local conform = require("conform")

conform.setup({
	formatters_by_ft = {
		lua = { "stylua" },
		nix = { "alejandra" },
	},
	format_on_save = {
		lsp_fallback = true,
		async = false,
		timeout_ms = 1000,
	},
})
