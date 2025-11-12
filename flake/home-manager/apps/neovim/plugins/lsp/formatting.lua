local conform = require("conform")
local util = require("conform.util")

conform.setup({
	formatters_by_ft = {
		-- lua = { "stylua" },
		python = { "isort", "black" },
		nix = { "alejandra" },
		json = { "prettierd" },
		-- jsonc = { "prettierd" },
		css = { "prettierd" },
		javascript = { "prettierd" },
		javascriptreact = { "prettierd" },
		typescript = { "prettierd" },
		typescriptreact = { "prettierd" },
		php = { "php-cs-fixer" },
		blade = { "blade-formatter" },
		go = { "gofumpt" },
	},
	formatters = {
		-- ["php-cs-fixer"] = {
		-- 	meta = {
		-- 		url = "https://github.com/PHP-CS-Fixer/PHP-CS-Fixer",
		-- 		description = "The PHP Coding Standards Fixer.",
		-- 	},
		-- 	command = util.find_executable({
		-- 		"tools/php-cs-fixer/vendor/bin/php-cs-fixer",
		-- 		"vendor/bin/php-cs-fixer",
		-- 	}, "php-cs-fixer"),
		-- 	args = { "fix", "$FILENAME", "--allow-risky=yes" },
		-- 	stdin = false,
		-- 	cwd = util.root_file({ "composer.json" }),
		-- },
		["blade-formatter"] = {
			meta = {
				url = "https://github.com/shufo/blade-formatter",
				description = "An opinionated blade template formatter for Laravel that respects readability.",
			},
			command = "blade-formatter",
			args = { "--stdin" },
			stdin = true,
			cwd = util.root_file({ "composer.json", "composer.lock" }),
		},
	},
	format_on_save = {
		lsp_fallback = true,
		async = false,
		timeout_ms = 1000,
	},
	notify_on_error = true,
})

require("guess-indent").setup({
	auto_cmd = true,
})
