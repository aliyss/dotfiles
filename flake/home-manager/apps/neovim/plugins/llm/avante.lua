require("avante").setup({
	provider = "llama-swap",
	mode = "agentic",
	auto_suggestions_provider = "llama-swap",
	providers = {
		["llama-swap"] = {
			__inherited_from = "openai",
			endpoint = "http://localhost:8012/v1",
			model = "qwen2.5-7b",
			extra_request_body = {
				temperature = 0,
				max_tokens = 8192,
			},
		},
		["opencode"] = {
			__inherited_from = "openai",
			endpoint = "https://opencode.ai/zen/go/v1",
			model = "deepseek-v4-flash",
			api_key_name = "OPENCODE_API_KEY",
			extra_request_body = {
				max_tokens = 65536,
			},
		},
	},
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
