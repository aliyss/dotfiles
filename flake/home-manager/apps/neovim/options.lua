local g = vim.g
local o = vim.o

g.mapleader = " "
g.maplocalleader = " "
g.db_ui_use_nerd_fonts = 1

o.termguicolors = true
o.clipboard = "unnamedplus"

o.scrolloff = 8

o.timeoutlen = 500
o.updatetime = 200

o.number = true
o.numberwidth = 3
o.signcolumn = "yes"
o.relativenumber = true
o.cursorline = true

o.wrap = true
o.linebreak = true

o.expandtab = true
o.cindent = true
o.autoindent = true
o.tabstop = 4
o.shiftwidth = 4
o.smarttab = true
o.softtabstop = 4

o.ignorecase = false
o.smartcase = true

o.backup = false
o.writebackup = false
o.undofile = true
o.swapfile = false

-- Live reload when files are changed outside Neovim (needed for opencode/ACP edits)
o.autoread = true
o.updatetime = 200 -- already set above, keep low for CursorHold checktime

o.history = 50

o.splitright = true
o.splitbelow = true

o.mouse = "a"

-- Fallback autoread trigger (redundant with AvanteOpencodeReload, but useful globally)
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
	group = vim.api.nvim_create_augroup("AutoReadCheck", { clear = true }),
	callback = function()
		if vim.fn.getcmdwintype() == "" then vim.cmd("checktime") end
	end,
})
