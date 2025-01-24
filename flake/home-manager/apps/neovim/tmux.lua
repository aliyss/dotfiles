if vim.env.TMUX then
	vim.api.nvim_create_autocmd("BufEnter", {
		pattern = "*",
		callback = function()
			local filename = vim.fn.expand("%:t")
			os.execute("tmux rename-window '" .. filename .. "'")
		end,
	})

	vim.api.nvim_create_autocmd("VimLeave", {
		pattern = "*",
		callback = function()
			os.execute("tmux setw automatic-rename")
		end,
	})
end
