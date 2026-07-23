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

if vim.env.HERDR_ENV then
  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*",
    callback = function()
      local filename = vim.fn.expand("%:t")
      local tab_id = vim.env.HERDR_TAB_ID
      if tab_id and filename ~= "" then
        vim.fn.system({ "herdr", "tab", "rename", tab_id, filename })
      end
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    pattern = "*",
    callback = function()
      local tab_id = vim.env.HERDR_TAB_ID
      if tab_id then
        vim.fn.system({ "herdr", "tab", "rename", tab_id, "nvim" })
      end
    end,
  })
end
