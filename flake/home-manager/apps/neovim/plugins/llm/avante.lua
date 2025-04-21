require("avante_lib").load()
require("avante").setup({
	provider = "ollama",
	-- auto_suggestions_provider = "ollama",
	cursor_applying_provider = "ollama",
	ollama = {
		api_key_name = "",
		model = "qwen2.5-coder",
		options = {
			num_ctx = 32768,
			temperature = 0,
		},
		stream = true,
	},
	hints = {
		enabled = true,
	},
	behavior = {
		auto_suggestions = false,
		auto_set_highlight_group = true,
		auto_set_keymaps = true,
		auto_apply_diff_after_generation = false,
		support_paste_from_clipboard = true,
		enable_cursor_planning_mode = true,
	},
})
