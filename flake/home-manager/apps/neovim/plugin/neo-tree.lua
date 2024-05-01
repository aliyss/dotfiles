require("neo-tree").setup({
    close_if_last_window = false,
    enable_git_status = true,
    enable_diagnostics = true,
    filesystem = {
        follow_current_file = { enabled = true, },
        filtered_items = {
            visible = true,
            show_hidden_count = true,
            hide_dotfiles = false,
            hide_gitignored = true,
        }
    },
    event_handlers = {
        {
            event = "file_opened",
            handler = function(file_path)
              -- auto close
              -- vimc.cmd("Neotree close")
              -- OR
              require("neo-tree.command").execute({ action = "close" })
            end
          },

        }
})
