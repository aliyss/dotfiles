local treesitter = require("nvim-treesitter.configs")

treesitter.setup({
    highlight = {
        enable = true,
    },
    indent = {
        enable = true,
    },
    autotag = {
        enable = true,
    },
})
