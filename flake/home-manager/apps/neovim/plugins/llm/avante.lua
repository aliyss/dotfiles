require("avante").setup({
	provider = "opencode",
	mode = "agentic",
	auto_suggestions_provider = "local-llm",
	-- ACP providers: use `opencode acp` for full agentic capabilities (tools, MCP, AGENTS.md, etc.)
	-- see https://opencode.ai/docs/acp/#avantenvim
	acp_providers = {
		["opencode"] = {
			command = "opencode",
			args = { "acp" },
			-- env = { OPENCODE_API_KEY = os.getenv("OPENCODE_API_KEY") } -- uncomment if needed; Zen auth from ~/.local/share/opencode/auth.json is used by default
		},
	},
	providers = {
		-- Local llama.cpp (Vulkan on the Arc iGPU): hosts/blisspla/services/local-llm.nix
		-- List models with `curl -s http://localhost:8012/v1/models`.
		["local-llm"] = {
			__inherited_from = "openai",
			endpoint = "http://localhost:8012/v1",
			model = "qwen3.5-9b",
			extra_request_body = {
				temperature = 0,
				max_tokens = 8192,
			},
		},
		-- Optional: direct Zen OpenAI-compatible endpoint (no tools, just LLM).
		-- Kept as "opencode-zen" so it doesn't collide with the ACP "opencode" provider.
		-- Switch with :AvanteSwitchProvider opencode-zen if you want raw LLM without opencode agent.
		["opencode-zen"] = {
			__inherited_from = "openai",
			endpoint = "https://opencode.ai/zen/v1",
			model = "opencode/muse-spark-1.2-contributor-free",
			api_key_name = "OPENCODE_API_KEY",
			extra_request_body = {
				max_tokens = 65536,
			},
		},
	},
	instructions_file = "AGENTS.md",
	-- override_prompt_dir = vim.fn.expand("~/.config/flake/home-manager/apps/neovim/plugins/llm/prompts"),
	behaviour = {
		auto_suggestions = false,
		auto_set_highlight_group = true,
		auto_set_keymaps = true,
		auto_apply_diff_after_generation = false,
		support_paste_from_clipboard = true,
		minimize_diff = true,
		enable_token_counting = true,
	},
})

vim.keymap.set("v", "<leader>ae", function()
	require("avante.api").edit()
end, { desc = "Edit selection with Avante" })

vim.keymap.set("v", "<leader>aa", function()
	require("avante.api").ask()
end, { desc = "Ask Avante about selection" })

-- Live reload: Avante+ACP edits files via opencode tools directly on disk,
-- so we need checktime to reflect changes without :e! .
-- (opencode.nvim does this via opts.events.reload; Avante needs this)
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
	group = vim.api.nvim_create_augroup("AvanteOpencodeReload", { clear = true }),
	callback = function()
		if vim.fn.getcmdwintype() == "" then vim.cmd("checktime") end
	end,
	desc = "Reload buffer if changed on disk (opencode ACP)",
})
