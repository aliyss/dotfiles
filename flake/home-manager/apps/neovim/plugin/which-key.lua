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
		},
		e = {
			"<cmd>Neotree toggle<cr>",
			"Open Tree",
		},
		l = {
			name = "+LSP",
			e = {

				"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
				"Buffer Diagnostics (Trouble)",
			},
		},
		d = {
			name = "+Debugging",
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
			l = {
				function()
					dap.list_breakpoints()
				end,
				"List Breakpoints",
			},
		},
		t = {
			name = "+Trouble",
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
