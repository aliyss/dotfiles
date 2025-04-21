local mason = require("mason")
local mason_lspconfig = require("mason-lspconfig")
local mason_tool_installer = require("mason-tool-installer")

mason.setup({
	ui = {
		icons = {
			package_installed = "✓",
			package_pending = "➜",
			package_uninstalled = "✗",
		},
	},
})

mason_lspconfig.setup({
	ensure_installed = {
		"ts_ls",
		"html",
		"lua_ls",
		"basedpyright",
		"nil_ls",
		"vimls",
		"phpactor",
		"intelephense",
		"hyprls",
		"gopls",
	},
})

mason_tool_installer.setup({
	ensure_installed = {},
})
