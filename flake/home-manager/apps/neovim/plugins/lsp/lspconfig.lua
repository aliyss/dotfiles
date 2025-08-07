local lspconfig = require("lspconfig")
local cmp_nvim_lsp = require("cmp_nvim_lsp")

vim.filetype.add({
	filename = {
		[".env"] = "config",
		[".conf"] = "config",
		[".todo"] = "txt",
	},
	pattern = {
		["requirement.*.txt"] = "config",
		["gitconf.*"] = "gitconfig",
		[".*.http"] = "http",
		[".*%.blade%.php"] = "blade",
		[".*.hl"] = "hyprlang",
		["hypr.*.conf"] = "hyprlang",
	},
})

vim.api.nvim_create_autocmd("LSPAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(ev)
		local opts = { buffer = ev.buf, silent = true }

		local bufmap = function(keys, func, vopts)
			vim.keymap.set("n", keys, func, vopts)
		end

		opts.desc = "Go to References"
		bufmap("gr", require("telescope.builtin").lsp_references, opts)
		opts.desc = "Go to Definition"
		bufmap("gd", vim.lsp.buf.definition, opts)

		opts.desc = "Go to Declaration"
		bufmap("gD", vim.lsp.buf.declaration, opts)
		opts.desc = "Go to Implementation"
		bufmap("gI", vim.lsp.buf.implementation, opts)

		opts.desc = "LSP Rename"
		bufmap("<leader>lr", vim.lsp.buf.rename, opts)

		opts.desc = "Code Action"
		bufmap("<leader>la", vim.lsp.buf.code_action, opts)

		opts.desc = "Show Documentation"
		bufmap("<leader>lD", vim.lsp.buf.hover, opts)

		opts.desc = "Show Type Definition"
		bufmap("<leader>ld", vim.lsp.buf.type_definition, opts)
		opts.desc = "Show Document Symbols"
		bufmap("<leader>ls", require("telescope.builtin").lsp_document_symbols, opts)
		opts.desc = "Show Workspace Symbols"
		bufmap("<leader>lS", require("telescope.builtin").lsp_dynamic_workspace_symbols, opts)

		bufmap("K", vim.lsp.buf.hover)
	end,
})

local capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
local on_attach = function(_, bufnr)
	vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
end

local signs = { Error = " ", Warn = " ", Hint = "󰘥 ", Info = " " }

for type, icon in pairs(signs) do
	local hl = "DiagnosticSign" .. type
	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

lspconfig["lua_ls"].setup({
	on_attach = on_attach,
	capabilities = capabilities,
	settings = {
		Lua = {
			runtime = {
				version = "LuaJIT",
			},
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				checkThirdParty = false,
				library = {
					unpack(vim.api.nvim_get_runtime_file("", true)),
					"${3rd}/luv/library",
				},
			},
			hint = {
				enable = true,
				arrayIndex = "Auto",
				await = true,
				paramName = "All",
				paramType = true,
				semicolon = "SameLine",
				setType = true,
			},
		},
	},
})

local util = require("lspconfig/util")

lspconfig["basedpyright"].setup({
	on_attach = on_attach,
	capabilities = capabilities,
	settings = {
		basedpyright = {
			typeCheckingMode = "recommended",
			analysis = {
				autoSearchPaths = true,
				useLibraryCodeForTypes = true,
				autoSearchPaths = true,
				diagnosticMode = "workspace",
				diagnosticSeverityOverrides = {
					reportUnusedCallResult = "none",
					reportUnknownMemberType = "none",
					reportUntypedFunctionDecorator = "none",
				},
			},
		},
	},
})

lspconfig["gopls"].setup({
	on_attach = on_attach,
	capabilities = capabilities,
	cmd = { "gopls" },
	filetypes = { "go", "gomod", "gowork", "gotmpl" },
	root_dir = util.root_pattern("go.mod", "go.work", ".git"),
	settings = {
		gopls = {
			completeUnimported = true,
			usePlaceholders = true,
			analyses = {
				unusedparams = true,
			},
		},
	},
})

lspconfig["phpactor"].setup({
	on_attach = on_attach,
	capabilities = capabilities,
})

lspconfig["nil_ls"].setup({
	on_attach = on_attach,
	capabilities = capabilities,
})

lspconfig["hyprls"].setup({
	on_attach = on_attach,
	capabilities = capabilities,
})

lspconfig["vimls"].setup({
	on_attach = on_attach,
	capabilities = capabilities,
	filetypes = { "vim" },
})

lspconfig["ts_ls"].setup({
	on_attach = on_attach,
	capabilities = capabilities,
	init_options = {
		plugins = {
			{
				name = "@vue/typescript-plugin",
				location = vim.g.vue_ls_path,
				languages = { "javascript", "typescript", "vue" },
			},
		},
	},
})

lspconfig["volar"].setup({
	on_attach = on_attach,
	capabilities = capabilities,
})

lspconfig["postgres_lsp"].setup({
	on_attach = on_attach,
	capabilities = capabilities,
	cmd = { "postgrestools", "lsp-proxy", "--log-path", "./output.log" },
	single_file_support = true,
})

lspconfig["tailwindcss"].setup({
	capabilities = capabilities,
})

lspconfig["rust_analyzer"].setup({
	on_attach = on_attach,
	capabilities = capabilities,
	filetypes = { "rust" },
	root_dir = util.root_pattern("Cargo.toml"),
	settings = {
		["rust-analyzer"] = {
			check = {
				command = "clippy",
			},
			cargo = {
				allFeatures = true,
			},
			diagnostics = {
				enable = true,
			},
		},
	},
})

local configs = require("lspconfig.configs")

configs.blade = {
	default_config = {
		cmd = { "/home/aliyss/Sources/laravel-dev-tools/laravel-dev-tools", "lsp" },
		filetypes = { "blade" },
		root_dir = function(pattern)
			local cwd = vim.loop.cwd()
			vim.notify(cwd)
			local root = util.root_pattern("composer.json", ".git")(pattern)
			vim.notify(root)

			-- prefer cwd if root is a descendant
			return util.path.is_descendant(cwd, root) and cwd or root
		end,
		settings = {},
	},
}

lspconfig["blade"].setup({
	on_attach = on_attach,
	capabilities = capabilities,
})

require("neodev").setup({
	library = { plugins = { "nvim-dap-ui" }, types = true },
})
