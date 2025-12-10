local luasnip = require("luasnip")

require("luasnip.loaders.from_vscode").lazy_load()

luasnip.config.setup({})

require("blink-cmp").setup({
    appearance = {
        nerd_font_variant = 'mono'
    },
    snippets = {
        preset = 'luasnip',
        expand = function(snippet)
            luasnip.lsp_expand(snippet)
        end,
        active = function(filter)
            if filter and filter.direction then
                return luasnip.jumpable(filter.direction)
            end
            return luasnip.in_snippet()
        end,
        jump = function(direction)
            luasnip.jump(direction)
        end,
    },
    sources = {
        default = { "lsp", "path", "snippets", "buffer", "copilot", "dadbod" },
        providers = {
            copilot = {
                name = "copilot",
                enabled = true,
                module = "blink-cmp-copilot",
                score_offset = 1200,
                async = true,
                max_items = 3,
            },
            dadbod = {
                name = "dadbod",
                enabled = true,
                module = "vim_dadbod_completion.blink",
                score_offset = 1100,
            },
            lsp = {
                name = "lsp",
                enabled = true,
                module = "blink.cmp.sources.lsp",
                score_offset = 1000,
            },
        }
    },
    keymap = {
        preset = "super-tab",
        ["<Tab>"] = {
            function(cmp)
                if cmp.snippet_active() then
                    return cmp.accept()
                else
                    return cmp.select_and_accept()
                end
            end,
            "snippet_forward",
            "fallback",
        },
        ["<S-Tab>"] = {
            "snippet_backward",
            "fallback"
        }
    },
    completion = {
        ghost_text = {
            enabled = true,
        },
        documentation = {
            auto_show = true,
            auto_show_delay_ms = 500,
        },
        menu = {
            draw = {
                -- We don't need label_description now because label and label_description are already
                -- combined together in label by colorful-menu.nvim.
                columns = { { "kind_icon" }, { "label", gap = 1 } },
                components = {
                    label = {
                        text = function(ctx)
                            return require("colorful-menu").blink_components_text(ctx)
                        end,
                        highlight = function(ctx)
                            return require("colorful-menu").blink_components_highlight(ctx)
                        end,
                    },
                },
            },
            direction_priority = function()
                local ctx = require('blink.cmp').get_context()
                local item = require('blink.cmp').get_selected_item()
                if ctx == nil or item == nil then return { 's', 'n' } end

                local item_text = item.textEdit ~= nil and item.textEdit.newText or item.insertText or item.label
                local is_multi_line = item_text:find('\n') ~= nil

                -- after showing the menu upwards, we want to maintain that direction
                -- until we re-open the menu, so store the context id in a global variable
                if is_multi_line or vim.g.blink_cmp_upwards_ctx_id == ctx.id then
                    vim.g.blink_cmp_upwards_ctx_id = ctx.id
                    return { 'n', 's' }
                end
                return { 's', 'n' }
            end,
        },
    },
})
