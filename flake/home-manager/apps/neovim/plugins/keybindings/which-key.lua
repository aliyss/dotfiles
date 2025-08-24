local wk = require("which-key")
local harpoon = require("harpoon")
local todo_comments = require("todo-comments")
local dap = require("dap")

vim.o.timeout = true
vim.o.timeoutlen = 300

local count_bufs_by_type = function(loaded_only)
	loaded_only = (loaded_only == nil and true or loaded_only)
	local count = { normal = 0, acwrite = 0, help = 0, nofile = 0, nowrite = 0, quickfix = 0, terminal = 0, prompt = 0 }
	local buftypes = vim.api.nvim_list_bufs()
	for _, bufname in pairs(buftypes) do
		if (not loaded_only) or vim.api.nvim_buf_is_loaded(bufname) then
			local buftype = vim.api.nvim_buf_get_option(bufname, "buftype")
			buftype = buftype ~= "" and buftype or "normal"
			count[buftype] = count[buftype] + 1
		end
	end
	return count
end

wk.setup({
	icons = {
		rules = false,
		mappings = false,
	},
})

wk.add({
	-- { "<leader>a", group = "AutoSession" },
	-- { "<leader>as", require("auto-session.session-lens").search_session, desc = "Save Session" },
	{ "<leader>b", group = "Buffer" },
	{
		"<leader>ba",
		function()
			harpoon:list():add()
		end,
		desc = "Add Buffer",
	},
	{ "<leader>bb", "<cmd>bprev<cr>", desc = "Previous Buffer" },
	{
		"<leader>bc",

		function()
			-- local bufTable = count_bufs_by_type()
			vim.cmd("bdelete")
			-- if bufTable.normal <= 1 then
			-- 	vim.cmd("Dashboard")
			-- end
		end,
		desc = "Close Buffer",
	},
	{
		"<leader>bj",

		function()
			harpoon.ui:toggle_quick_menu(harpoon:list())
		end,
		desc = "List Saved Buffers",
	},
	{ "<leader>bl", "<cmd>Telescope buffers<cr>", desc = "List Open Buffers" },
	{ "<leader>bn", "<cmd>bnext<cr>", desc = "Next Buffer" },
	{
		"<leader>br",
		function()
			harpoon:list():remove()
		end,
		desc = "Remove Buffer",
	},
	{ "<leader>c", group = "Launch" },
	{ "<leader>cd", "<cmd>Dashboard<cr>", desc = "Open Dashboard" },
	{ "<leader>ch", "<cmd>:e ~/.config/hypr/hyprland.conf<cr>", desc = "Open Hyprland Config" },
	{ "<leader>cn", "<cmd>:e ~/.config/flake/home-manager/apps/neovim.nix<cr>", desc = "Open Neovim Config" },
	{ "<leader>d", group = "Debugging/Database" },
	{
		"<leader>dB",

		function()
			vim.cmd(":tabnew")
			vim.cmd(":DBUI")
		end,
		desc = "Open DBUI",
	},
	{
		"<leader>da",
		function()
			require("dap.ext.vscode").load_launchjs(nil, {})
			dap.continue()
		end,
		desc = "Launch Debugger",
	},
	{
		"<leader>db",

		function()
			dap.toggle_breakpoint()
		end,
		desc = "Toggle Breakpoint",
	},
	{
		"<leader>dc",

		function()
			require("dapui").toggle(3)
			require("dapui").close(1)
			require("dapui").close(2)
		end,
		desc = "Toggle Debugger Console UI",
	},
	{
		"<leader>de",
		function()
			vim.cmd(":DBUIToggle")
		end,
		desc = "Toggle DBUI",
	},
	{
		"<leader>dl",
		function()
			dap.list_breakpoints()
		end,
		desc = "List Breakpoints",
	},
	{
		"<leader>dp",
		function()
			dap.pause()
		end,
		desc = "Pause Debugger",
	},
	{
		"<leader>dr",
		function()
			dap.restart()
		end,
		desc = "Restart Debugger",
	},
	{
		"<leader>ds",
		function()
			dap.disconnect()
		end,
		desc = "Stop Debugger",
	},
	{
		"<leader>du",

		function()
			require("dapui").toggle(1)
			require("dapui").toggle(2)
			require("dapui").close(3)
		end,
		desc = "Toggle Debugger UI",
	},
	{ "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Open Tree" },
	{ "<leader>f", group = "Find" },
	{ "<leader>fG", "<cmd>Telescope live_grep<cr>", desc = "Grep" },
	{ "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "List Buffers" },
	{ "<leader>fc", "<cmd>Telescope colorscheme<cr>", desc = "Colorscheme" },
	{ "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find File" },
	{ "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
	{ "<leader>fk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
	{ "<leader>fm", "<cmd>Telescope marks<cr>", desc = "Marks" },
	{ "<leader>fp", "<cmd>Telescope projects<cr>", desc = "Projects" },
	{ "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
	{ "<leader>fu", "<cmd>Telescope undo<cr>", desc = "Undo" },
	{ "<leader>fx", "<cmd>Telescope commands<cr>", desc = "Commands" },

	{ "<leader>g", group = "Git" },
	{ "<leader>gg", group = "Gopher" },
	{ "<leader>ggf", "<cmd>Telescope gopher_files<cr>", desc = "Gopher Files" },
	{ "<leader>ggm", "<cmd>Telescope gopher_mods<cr>", desc = "Gopher Mods" },
	{ "<leader>ggp", "<cmd>Telescope gopher_pkgs<cr>", desc = "Gopher Packages" },
	{ "<leader>ggv", "<cmd>Telescope gopher_vars<cr>", desc = "Gopher Vars" },
	{ "<leader>ggw", "<cmd>Telescope gopher_workspaces<cr>", desc = "Gopher Workspaces" },
	{ "<leader>gf", group = "Telescope" },
	{ "<leader>gfR", "<cmd>Telescope git_branch_remote<cr>", desc = "Git Remote Branches" },
	{ "<leader>gfb", "<cmd>Telescope git_branches<cr>", desc = "Git Branches" },
	{ "<leader>gfc", "<cmd>Telescope git_commits<cr>", desc = "Git Commits" },
	{ "<leader>gff", "<cmd>Telescope git_files<cr>", desc = "Git Files" },
	{ "<leader>gfg", "<cmd>Telescope git_status<cr>", desc = "Git Status" },
	{ "<leader>gfr", "<cmd>Telescope git_bcommits<cr>", desc = "Git Branch Commits" },
	{ "<leader>gfs", "<cmd>Telescope git_stash<cr>", desc = "Git Stash" },
	{ "<leader>gp", "<cmd>Pipeline toggle<cr>", desc = "Git Pipeline" },

	{ "<leader>h", group = "Saved" },
	{
		"<leader>hh",
		function()
			harpoon:list():prev()
		end,
		desc = "Previous Buffer",
	},
	{
		"<leader>hn",
		function()
			harpoon:list():next()
		end,
		desc = "Next Buffer",
	},
	{ "<leader>l", group = "LSP" },
	{ "<leader>le", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
	{ "<leader>t", group = "Trouble/Tabs" },
	{
		"<leader>tN",
		function()
			todo_comments.jump_next()
		end,
		desc = "Next Todo Comment",
	},
	{
		"<leader>tT",
		function()
			todo_comments.jump_prev()
		end,
		desc = "Previous Todo Comment",
	},
	{ "<leader>ta", "<cmd>tabnew<cr>", desc = "New Tab" },
	{ "<leader>tb", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics" },
	{ "<leader>td", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics" },
	{ "<leader>tl", "<cmd>Trouble loclist toggle<cr>", desc = "Location List" },
	{ "<leader>tn", "<cmd>tabnext<cr>", desc = "Next Tab" },
	{ "<leader>tq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List" },
	{
		"<leader>tr",
		"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
		desc = "LSP Definitions / references / ...",
	},
	{ "<leader>tt", "<cmd>tabprevious<cr>", desc = "Previous Tab" },
	{ "<leader>w", group = "Window" },
	{ "<leader>wc", "<cmd>wincmd c<cr>", desc = "Close Window" },
	{ "<leader>wh", "<cmd>NvimTmuxNavigateLeft<cr>", desc = "Left Window" },
	{ "<leader>wj", "<cmd>NvimTmuxNavigateDown<cr>", desc = "Bottom Window" },
	{ "<leader>wk", "<cmd>NvimTmuxNavigateUp<cr>", desc = "Top Window" },
	{ "<leader>wl", "<cmd>NvimTmuxNavigateRight<cr>", desc = "Right Window" },
	{ "<leader>ws", "<cmd>wincmd s<cr>", desc = "Split Window Horizontally" },
	{ "<leader>wv", "<cmd>wincmd v<cr>", desc = "Split Window Vertically" },
	{ "<leader>ww", "<cmd>NvimTmuxNavigateNext<cr>", desc = "Next Window" },
	{
		"<leader>me",
		function()
			vim.cmd(":HimalayaToggle")
		end,
		desc = "Toggle Himalaya",
	},
})
