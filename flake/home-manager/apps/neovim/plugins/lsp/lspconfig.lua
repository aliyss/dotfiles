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
		-- [".*%.blade%.php"] = "blade",
		[".*.hl"] = "hyprlang",
		["hypr.*.conf"] = "hyprlang",
		-- [".*.md"] = "marksman",
	},
})

vim.api.nvim_create_autocmd("LSPAttach", {
	-- group = vim.api.nvim_create_augroup("UserLspConfig", {}),
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

		-- local bufnr = ev.buf
		-- local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))
		--
		-- if client:supports_method(vim.lsp.protocol.Methods.textDocument_inlineCompletion, bufnr) then
		-- 	vim.lsp.inline_completion.enable(true, { bufnr = bufnr })
		-- 	vim.keymap.set(
		-- 		'i',
		-- 		'<C-F>',
		-- 		vim.lsp.inline_completion.get,
		-- 		{ desc = 'LSP: accept inline completion', buffer = bufnr }
		-- 	)
		-- 	vim.keymap.set(
		-- 		'i',
		-- 		'<C-G>',
		-- 		vim.lsp.inline_completion.select,
		-- 		{ desc = 'LSP: switch inline completion', buffer = bufnr }
		-- 	)
		-- end
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

vim.lsp.config("lua_ls", {
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

vim.lsp.config("basedpyright", {
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

vim.lsp.config("gopls", {
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

vim.lsp.config("marksman", {
	on_attach = on_attach,
	capabilities = capabilities,
})

vim.lsp.config("phpactor", {
	on_attach = on_attach,
	capabilities = capabilities,
})

vim.lsp.config("nil_ls", {
	on_attach = on_attach,
	capabilities = capabilities,
})

vim.lsp.config("hyprls", {
	on_attach = on_attach,
	capabilities = capabilities,
})

vim.lsp.config("vimls", {
	on_attach = on_attach,
	capabilities = capabilities,
	filetypes = { "vim" },
})

vim.lsp.config("ts_ls", {
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

vim.lsp.config("volar", {
	on_attach = on_attach,
	capabilities = capabilities,
})

vim.lsp.config("postgres_lsp", {
	on_attach = on_attach,
	capabilities = capabilities,
	cmd = { "postgrestools", "lsp-proxy", "--log-path", "./output.log" },
	single_file_support = true,
})

vim.lsp.config("tailwindcss", {
	capabilities = capabilities,
})

vim.lsp.config("rust_analyzer", {
	on_attach = on_attach,
	capabilities = capabilities,
	cmd = { 'rust-analyzer' },
	filetypes = { 'rust' },
	root_markers = { "Cargo.toml", ".git" },
	single_file_support = true,
	-- root_dir = util.root_pattern("Cargo.toml"),
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

vim.lsp.config("copilot", {
	on_attach = on_attach,
	capabilities = capabilities,
})

-- vim.lsp.config(
-- 	"copilotlsp-nvim/copilot-lsp", {
-- 		init = function()
-- 			vim.g.copilot_nes_debounce = 500
-- 			vim.lsp.enable("copilot_ls")
--
-- 			vim.keymap.set("n", "<tab>", function()
-- 				local bufnr = vim.api.nvim_get_current_buf()
-- 				local state = vim.b[bufnr].nes_state
-- 				if state then
-- 					-- Try to jump to the start of the suggestion edit.
-- 					-- If already at the start, then apply the pending suggestion and jump to the end of the edit.
-- 					local _ = require("copilot-lsp.nes").walk_cursor_start_edit()
-- 						or (
-- 							require("copilot-lsp.nes").apply_pending_nes()
-- 							and require("copilot-lsp.nes").walk_cursor_end_edit()
-- 						)
-- 					return nil
-- 				else
-- 					-- Resolving the terminal's inability to distinguish between `TAB` and `<C-i>` in normal mode
-- 					return "<C-i>"
-- 				end
-- 			end, { desc = "Accept Copilot NES suggestion", expr = true })
-- 		end,
-- 	}
-- )

local configs = require("lspconfig.configs")

-- configs.blade = {
-- 	default_config = {
-- 		cmd = { "/home/aliyss/Sources/laravel-dev-tools/laravel-dev-tools", "lsp" },
-- 		filetypes = { "blade" },
-- 		root_dir = function(pattern)
-- 			local cwd = vim.loop.cwd()
-- 			vim.notify(cwd)
-- 			local root = util.root_pattern("composer.json", ".git")(pattern)
-- 			vim.notify(root)
--
-- 			-- prefer cwd if root is a descendant
-- 			return util.path.is_descendant(cwd, root) and cwd or root
-- 		end,
-- 		settings = {},
-- 	},
-- }

-- vim.lsp.config("blade", {
-- 	on_attach = on_attach,
-- 	capabilities = capabilities,
-- })

require("neodev").setup({
	library = { plugins = { "nvim-dap-ui" }, types = true },
})

vim.lsp.enable({
	"lua_ls",
	"nil_ls",
	"basedpyright",
	"vim",
	-- "blade",
	"ts_ls",
	"postgres_lsp",
	"tailwindcss",
	"rust_analyzer",
	"marksman"
})
-- vim.lsp.enable("copilotlsp-nvim/copilot-lsp")
