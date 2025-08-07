require("avante_lib").load()
require("avante").setup({
	provider = "claude",
	mode = "agentic",
	-- auto_suggestions_provider = "claude",
	providers = {
		-- claude = {
		-- 	endpoint = "https://api.anthropic.com",
		-- 	model = "claude-sonnet-4-20250514",
		-- 	extra_request_body = {
		-- 		temperature = 0.75,
		-- 		max_tokens = 20480,
		-- 	},
		-- },
		ollama = {
			api_key_name = "",
			model = "qwen2.5-coder",
			extra_request_body = {
				num_ctx = 32768,
				temperature = 0,
			},
			stream = true,
		},
	},
	hints = {
		enabled = true,
	},
	behavior = {
		auto_suggestions = true,
		auto_set_highlight_group = true,
		auto_set_keymaps = true,
		auto_apply_diff_after_generation = false,
		support_paste_from_clipboard = true,
		minimize_diff = true,
		enable_token_counting = true,
		auto_approve_tool_permissions = false,
	},
})
