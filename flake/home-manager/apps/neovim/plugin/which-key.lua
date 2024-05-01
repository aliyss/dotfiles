local wk = require("which-key")
local harpoon = require("harpoon")
local todo_comments = require("todo-comments")

vim.o.timeout = true
vim.o.timeoutlen = 300

count_bufs_by_type = function(loaded_only)
    loaded_only = (loaded_only == nil and true or loaded_only)
    count = {normal = 0, acwrite = 0, help = 0, nofile = 0,
    nowrite = 0, quickfix = 0, terminal = 0, prompt = 0}
    buftypes = vim.api.nvim_list_bufs()
    for _, bufname in pairs(buftypes) do
       if (not loaded_only) or vim.api.nvim_buf_is_loaded(bufname) then
           buftype = vim.api.nvim_buf_get_option(bufname, 'buftype')
           buftype = buftype ~= '' and buftype or 'normal'
           count[buftype] = count[buftype] + 1
       end
    end
    return count
end

wk.register({
  ["<leader>"] = {
    t = {
       name = "+Saved",
       N = {function() todo_comments.jump_next() end, "Next Todo Comment"},
       T = {function() todo_comments.jump_prev() end, "Previous Todo Comment"},
       n = {function() harpoon:list():next() end, "Next Buffer"},
       t = {function() harpoon:list():prev() end, "Previous Buffer"},
    },
    b = {
       name = "+Buffer",
       a = {function() harpoon:list():add() end, "Add Buffer"},
       c = {
          function()
             local bufTable = count_bufs_by_type()
             vim.cmd('bdelete')
             if (bufTable.normal <= 1) then
                vim.cmd('Dashboard')
             end
          end,
          "Close Buffer"
       },
       r = {
          function()
             harpoon:list():remove()
          end
          , "Remove Buffer"
       },
       j = {
          function() harpoon.ui:toggle_quick_menu(harpoon:list()) end,
          "List Saved Buffers"
       },
       l = {"<cmd>Telescope buffers<cr>", "List Open Buffers"},
       n = {"<cmd>bnext<cr>", "Next Buffer"},
       b = {"<cmd>bprev<cr>", "Previous Buffer"},
    },
    e = {
        "<cmd>Neotree toggle<cr>",
        "Open Tree",
    }
  },
})
