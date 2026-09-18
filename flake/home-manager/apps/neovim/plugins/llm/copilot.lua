-- Defensive patch for https://github.com/zbirenbaum/copilot.lua/issues/xxx
-- Fixes "api/init.lua:23: attempt to index local 'client' (a nil value)"
-- blink-cmp-copilot calls api.get_completions with nil client during startup race
do
  local ok, api = pcall(require, "copilot.api")
  if ok and not api._patched_for_nil_client then
    api._patched_for_nil_client = true
    local orig_request = api.request
    function api.request(client, method, params, callback)
      if not client then
        if callback then
          vim.schedule(function() callback("copilot client not ready", nil) end)
          return nil
        end
        return "copilot client not ready", nil, nil
      end
      return orig_request(client, method, params, callback)
    end
    local orig_notify = api.notify
    function api.notify(client, method, params)
      if not client then return false end
      return orig_notify(client, method, params)
    end
  end
  -- Also monkey-patch blink-cmp-copilot if loaded
  pcall(function()
    local bc = require("blink-cmp-copilot")
    if not bc._patched_for_nil_client and bc.get_completions then
      bc._patched_for_nil_client = true
      local orig = bc.get_completions
      bc.get_completions = function(self, context, callback)
        if not self.client then
          local clients = vim.lsp.get_clients({ name = "copilot" })
          self.client = clients[1]
        end
        if not self.client then
          return callback({ is_incomplete_forward = true, is_incomplete_backward = true, items = {} })
        end
        local ok2, err = pcall(orig, self, context, callback)
        if not ok2 then
          return callback({ is_incomplete_forward = true, is_incomplete_backward = true, items = {} })
        end
        return err
      end
    end
  end)
end

require("copilot").setup({
    file_types = {
        markdown = true
    },
    suggestion = {
        enabled = true,
        auto_trigger = true,
        hide_during_completion = true,
        debounce = 75,
        trigger_on_accept = true,
        keymap = {
            accept = "<Tab>",
            accept_word = false,
            accept_line = false,
            next = "<M-]>",
            prev = "<M-[>",
            dismiss = "<C-]>",
        },
    },
    panel = { enabled = false },
    nes = {
        enabled = false,
        -- keymap = {
        --     accept_and_goto = "<Tab>",
        --     accept = false,
        --     dismiss = "<Esc>",
        -- },
    },
})


vim.api.nvim_create_autocmd("User", {
    pattern = "BlinkCmpMenuOpen",
    callback = function()
        vim.b.copilot_suggestion_hidden = true
    end,
})

vim.api.nvim_create_autocmd("User", {
    pattern = "BlinkCmpMenuClose",
    callback = function()
        vim.b.copilot_suggestion_hidden = false
    end,
})
