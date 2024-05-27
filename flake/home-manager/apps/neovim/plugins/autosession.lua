local autosession = require("auto-session")

autosession.setup({
	auto_session_suppress_dirs = { "~", "~/Downloads", "/" },
	session_lens = {
		buftypes_to_ignore = { "terminal", "nofile" },
		load_on_setup = true,
		theme_conf = { border = true },
		previewer = true,
	},
})
