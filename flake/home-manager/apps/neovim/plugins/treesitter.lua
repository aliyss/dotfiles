local treesitter = require("nvim-treesitter.configs")

local treesitter_config = {
	ignore_install = { "org" },
	highlight = {
		enable = true,
	},
	indent = {
		enable = true,
	},
	autotag = {
		enable = true,
	},
}

treesitter.setup(treesitter_config)
