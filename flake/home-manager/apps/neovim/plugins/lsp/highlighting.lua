local ts = require("nvim-treesitter.config")
ts.setup({
    ensure_installed = { "typescript", "tsx", "javascript", "lua" },
    highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
    },
    indent = {
        enable = true,
    },
    rainbow = {
        enable = true,
        extended_mode = true,
    },
    autotag = {
        enable = true,
    },
})

vim.treesitter.language.register('tsx', { 'javascript', 'typescript', 'typescriptreact' })

-- local parser_config = require "nvim-treesitter.parsers".get_parser_configs()
-- parser_config.tsx.filetype_to_parsername = { "javascript", "typescript.tsx" }

-- parser_config.blade = {
-- 	install_info = {
-- 		url = "https://github.com/EmranMR/tree-sitter-blade",
-- 		files = { "src/parser.c" },
-- 		branch = "main",
-- 	},
-- 	filetype = "blade",
-- }
