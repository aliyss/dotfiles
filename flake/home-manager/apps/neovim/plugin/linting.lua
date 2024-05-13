local lint = require("lint")

lint.linters_by_ft = {
	json = { "jsonlint" },
	python = { "pylint" },
}

local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
	group = lint_augroup,
	callback = function()
		lint.try_lint()
	end,
})

vim.keymap.set("n", "<leader>l", function()
	lint.try_lint()
end, { desc = "Lint file" })

lint.linters.pylint.cmd = "python"
lint.linters.pylint.args = { "-m", "pylint", "-f", "json" }
