-- local cmp = require("cmp")
local luasnip = require("luasnip")
local lspkind = require("lspkind")

require("luasnip.loaders.from_vscode").lazy_load()

luasnip.config.setup({})

-- cmp.setup({
-- 	experimental = {
-- 		ghost_text = true,
-- 	},
-- 	snippet = {
-- 		expand = function(args)
-- 			luasnip.lsp_expand(args.body)
-- 		end,
-- 	},
-- 	mapping = cmp.mapping.preset.insert({
-- 		["<C-n>"] = cmp.mapping.select_next_item(),
-- 		["<C-p>"] = cmp.mapping.select_prev_item(),
-- 		["<C-d>"] = cmp.mapping.scroll_docs(-4),
-- 		["<C-f>"] = cmp.mapping.scroll_docs(4),
-- 		["<C-Space>"] = cmp.mapping.complete({}),
-- 		["<CR>"] = cmp.mapping.confirm({
-- 			behavior = cmp.ConfirmBehavior.Replace,
-- 			select = true,
-- 		}),
-- 		["<Tab>"] = cmp.mapping(function(fallback)
-- 			if cmp.visible() then
-- 				cmp.select_next_item()
-- 			elseif luasnip.expand_or_locally_jumpable() then
-- 				luasnip.expand_or_jump()
-- 			else
-- 				fallback()
-- 			end
-- 		end, { "i", "s" }),
-- 		["<S-Tab>"] = cmp.mapping(function(fallback)
-- 			if cmp.visible() then
-- 				cmp.select_prev_item()
-- 			elseif luasnip.locally_jumpable(-1) then
-- 				luasnip.jump(-1)
-- 			else
-- 				fallback()
-- 			end
-- 		end, { "i", "s" }),
-- 	}),
-- 	sources = {
-- 		{ name = "orgmode" },
-- 		{ name = "nvim_lsp" },
-- 		{ name = "luasnip" },
-- 		{ name = "buffer" },
-- 		{ name = "path" },
-- 		{ name = "avante_commands" },
-- 		{ name = "avante_mentions" },
-- 		{ name = "avante_prompt_mentions" },
-- 	},
-- 	formatting = {
-- 		format = lspkind.cmp_format({
-- 			maxwidth = 50,
-- 			ellipsis_char = "...",
-- 		}),
-- 	},
-- 	appearance = {
-- 		menu = {
-- 			direction = 'above'
-- 		}
-- 	}
-- })

-- cmp.setup.filetype({
-- 	{ "sql" },
-- 	{
-- 		sources = {
-- 			{ name = "vim-dadbod-completion" },
-- 			{ name = "buffer" },
-- 		},
-- 	},
-- })

require("blink-cmp").setup({
    appearance = {
        nerd_font_variant = 'mono'
    },
    sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        providers = {
            lsp = {
                name = "lsp",
                enabled = true,
                module = "blink.cmp.sources.lsp",
                score_offset = 1000,
            },
            copilot = {
                name = "copilot",
                enabled = true,
                module = "blink.cmp.sources.copilot",
                score_offset = -100,
                async = true
            }
        }
    },
    keymap = {
        preset = "super-tab",
        ["<Tab>"] = {
            function(cmp)
                if vim.b[vim.api.nvim_get_current_buf()].nes_state then
                    cmp.hide()
                    return (
                        require("copilot-lsp.nes").apply_pending_nes()
                        and require("copilot-lsp.nes").walk_cursor_end_edit()
                    )
                end
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
