local wk = require("which-key")
local harpoon = require("harpoon")

vim.o.timeout = true
vim.o.timeoutlen = 300

wk.setup({
	icons = {
		rules = false,
		mappings = false,
	},
})

wk.add({
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
			vim.cmd("bdelete")
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
	{ "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Open Tree" },
	{ "<leader>f", group = "Find" },
	{ "<leader>fG", "<cmd>Telescope live_grep<cr>", desc = "Grep" },
	{ "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "List Buffers" },
	{ "<leader>fc", "<cmd>Telescope colorscheme<cr>", desc = "Colorscheme" },
	{ "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find File" },
	{ "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
	{ "<leader>fk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
	{ "<leader>fm", "<cmd>Telescope marks<cr>", desc = "Marks" },
	{ "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
	{ "<leader>fu", "<cmd>Telescope undo<cr>", desc = "Undo" },
	{ "<leader>fx", "<cmd>Telescope commands<cr>", desc = "Commands" },
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
	{ "<leader>w", group = "Window" },
	{ "<leader>wc", "<cmd>wincmd c<cr>", desc = "Close Window" },
	{ "<leader>wh", "<cmd>wincmd h<cr>", desc = "Left Window" },
	{ "<leader>wj", "<cmd>wincmd j<cr>", desc = "Bottom Window" },
	{ "<leader>wk", "<cmd>wincmd k<cr>", desc = "Top Window" },
	{ "<leader>wl", "<cmd>wincmd l<cr>", desc = "Right Window" },
	{ "<leader>ws", "<cmd>wincmd s<cr>", desc = "Split Window Horizontally" },
	{ "<leader>wv", "<cmd>wincmd v<cr>", desc = "Split Window Vertically" },
	{ "<leader>ww", "<cmd>wincmd w<cr>", desc = "Next Window" },
})