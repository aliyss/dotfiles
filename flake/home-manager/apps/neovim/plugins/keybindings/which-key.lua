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

wk.register({
	["<leader>"] = {
		a = {
			name = "+AutoSession",
			s = {
				require("auto-session.session-lens").search_session,
				"Save Session",
			},
		},
		f = {
			name = "+Find",
			f = { "<cmd>Telescope find_files<cr>", "Find File" },
			r = { "<cmd>Telescope oldfiles<cr>", "Recent Files" },
			G = { "<cmd>Telescope live_grep<cr>", "Grep" },
			b = { "<cmd>Telescope buffers<cr>", "List Buffers" },
			h = { "<cmd>Telescope help_tags<cr>", "Help Tags" },
			c = { "<cmd>Telescope colorscheme<cr>", "Colorscheme" },
			p = { "<cmd>Telescope projects<cr>", "Projects" },
			m = { "<cmd>Telescope marks<cr>", "Marks" },
			x = { "<cmd>Telescope commands<cr>", "Commands" },
			g = {
				name = "+Git",
				s = { "<cmd>Telescope git_stash<cr>", "Git Stash" },
				c = { "<cmd>Telescope git_commits<cr>", "Git Commits" },
				b = { "<cmd>Telescope git_branches<cr>", "Git Branches" },
				r = { "<cmd>Telescope git_bcommits<cr>", "Git Branch Commits" },
				R = { "<cmd>Telescope git_branch_remote<cr>", "Git Remote Branches" },
				f = { "<cmd>Telescope git_files<cr>", "Git Files" },
				g = { "<cmd>Telescope git_status<cr>", "Git Status" },
			},
			k = { "<cmd>Telescope keymaps<cr>", "Keymaps" },
			u = { "<cmd>Telescope undo<cr>", "Undo" },
		},
		h = {
			name = "+Saved",
			n = {
				function()
					harpoon:list():next()
				end,
				"Next Buffer",
			},
			t = {
				function()
					harpoon:list():prev()
				end,
				"Previous Buffer",
			},
		},
		b = {
			name = "+Buffer",
			a = {
				function()
					harpoon:list():add()
				end,
				"Add Buffer",
			},
			c = {
				function()
					local bufTable = count_bufs_by_type()
					vim.cmd("bdelete")
					if bufTable.normal <= 1 then
						vim.cmd("Dashboard")
					end
				end,
				"Close Buffer",
			},
			r = {
				function()
					harpoon:list():remove()
				end,
				"Remove Buffer",
			},
			j = {
				function()
					harpoon.ui:toggle_quick_menu(harpoon:list())
				end,
				"List Saved Buffers",
			},
			l = { "<cmd>Telescope buffers<cr>", "List Open Buffers" },
			n = { "<cmd>bnext<cr>", "Next Buffer" },
			b = { "<cmd>bprev<cr>", "Previous Buffer" },
		},
		w = {
			h = { "<cmd>NvimTmuxNavigateLeft<cr>", "Left Window" },
			j = { "<cmd>NvimTmuxNavigateDown<cr>", "Bottom Window" },
			k = { "<cmd>NvimTmuxNavigateUp<cr>", "Top Window" },
			l = { "<cmd>NvimTmuxNavigateRight<cr>", "Right Window" },
			w = { "<cmd>NvimTmuxNavigateNext<cr>", "Next Window" },
			c = { "<cmd>wincmd c<cr>", "Close Window" },
			s = { "<cmd>wincmd s<cr>", "Split Window Horizontally" },
			v = { "<cmd>wincmd v<cr>", "Split Window Vertically" },
		},
		e = {
			"<cmd>Neotree toggle<cr>",
			"Open Tree",
		},
		c = {
			name = "+Launch",
			d = {
				"<cmd>Dashboard<cr>",
				"Open Dashboard",
			},
			n = {
				"<cmd>:e ~/.config/flake/home-manager/apps/neovim.nix<cr>",
				"Open Neovim Config",
			},
			h = {
				"<cmd>:e ~/.config/hypr/hyprland.conf<cr>",
				"Open Hyprland Config",
			},
		},
		l = {
			name = "+LSP",
			e = {

				"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
				"Buffer Diagnostics (Trouble)",
			},
		},
		d = {
			name = "+Debugging/Database",
			a = {
				function()
					require("dap.ext.vscode").load_launchjs(nil, {})
					dap.continue()
				end,
				"Launch Debugger",
			},
			u = {
				function()
					require("dapui").toggle(1)
					require("dapui").toggle(2)
					require("dapui").close(3)
				end,
				"Toggle Debugger UI",
			},
			c = {
				function()
					require("dapui").toggle(3)
					require("dapui").close(1)
					require("dapui").close(2)
				end,
				"Toggle Debugger Console UI",
			},
			r = {
				function()
					dap.restart()
				end,
				"Restart Debugger",
			},
			p = {
				function()
					dap.pause()
				end,
				"Pause Debugger",
			},
			s = {
				function()
					dap.disconnect()
				end,
				"Stop Debugger",
			},
			b = {
				function()
					dap.toggle_breakpoint()
				end,
				"Toggle Breakpoint",
			},
			B = {
				function()
					vim.cmd(":tabnew")
					vim.cmd(":DBUI")
				end,
				"Open DBUI",
			},
			e = {
				function()
					vim.cmd(":DBUIToggle")
				end,
				"Toggle DBUI",
			},
			l = {
				function()
					dap.list_breakpoints()
				end,
				"List Breakpoints",
			},
		},
		t = {
			name = "+Trouble/Tabs",
			a = {
				"<cmd>tabnew<cr>",
				"New Tab",
			},
			t = {
				"<cmd>tabprevious<cr>",
				"Previous Tab",
			},
			n = {
				"<cmd>tabnext<cr>",
				"Next Tab",
			},
			d = {
				"<cmd>Trouble diagnostics toggle<cr>",
				"Diagnostics",
			},
			b = {
				"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
				"Buffer Diagnostics",
			},
			r = {
				"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
				"LSP Definitions / references / ...",
			},
			l = {
				"<cmd>Trouble loclist toggle<cr>",
				"Location List",
			},
			q = {
				"<cmd>Trouble qflist toggle<cr>",
				"Quickfix List",
			},
			N = {
				function()
					todo_comments.jump_next()
				end,
				"Next Todo Comment",
			},
			T = {
				function()
					todo_comments.jump_prev()
				end,
				"Previous Todo Comment",
			},
		},
	},
})
