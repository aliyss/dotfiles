require("pipeline").setup({
	--- The browser executable path to open workflow runs/jobs in
	browser = nil,
	--- Interval to refresh in seconds
	refresh_interval = 10,
	--- How much workflow runs and jobs should be indented
	indent = 2,
	providers = {
		github = {},
		gitlab = {},
	},
	--- Allowed hosts to fetch data from, github.com is always allowed
	allowed_hosts = {},
	icons = {
		workflow_dispatch = "⚡️",
		conclusion = {
			success = "✓",
			failure = "X",
			startup_failure = "X",
			cancelled = "⊘",
			skipped = "◌",
		},
		status = {
			unknown = "?",
			pending = "○",
			queued = "○",
			requested = "○",
			waiting = "○",
			in_progress = "●",
		},
	},
	highlights = {
		PipelineRunIconSuccess = { link = "DiagnosticOk" },
		PipelineRunIconFailure = { link = "DiagnosticError" },
		PipelineRunIconStartup_failure = { link = "DiagnosticVirtualTextError" },
		PipelineRunIconPending = { link = "DiagnosticVirtualTextWarn" },
		PipelineRunIconRequested = { link = "DiagnosticVirtualTextWarn" },
		PipelineRunIconWaiting = { link = "DiagnosticVirtualTextWarn" },
		PipelineRunIconIn_progress = { link = "DiagnosticVirtualTextWarn" },
		PipelineRunIconCancelled = { link = "Comment" },
		PipelineRunIconSkipped = { link = "Comment" },
		PipelineRunCancelled = { link = "Comment" },
		PipelineRunSkipped = { link = "Comment" },
		PipelineJobCancelled = { link = "Comment" },
		PipelineJobSkipped = { link = "Comment" },
		PipelineStepCancelled = { link = "Comment" },
		PipelineStepSkipped = { link = "Comment" },
	},
	split = {
		relative = "editor",
		position = "right",
		size = 100,
		win_options = {
			wrap = false,
			number = false,
			foldlevel = nil,
			foldcolumn = "0",
			cursorcolumn = false,
			signcolumn = "no",
		},
	},
})
