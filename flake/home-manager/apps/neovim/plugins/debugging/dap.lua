local dap = require("dap")

local enrich_config = function(finalConfig, on_config)
	local final_config = vim.deepcopy(finalConfig)

	-- Placeholder expansion for launch directives
	local placeholders = {
		["${file}"] = function(_)
			return vim.fn.expand("%:p")
		end,
		["${fileBasename}"] = function(_)
			return vim.fn.expand("%:t")
		end,
		["${fileBasenameNoExtension}"] = function(_)
			return vim.fn.fnamemodify(vim.fn.expand("%:t"), ":r")
		end,
		["${fileDirname}"] = function(_)
			return vim.fn.expand("%:p:h")
		end,
		["${fileExtname}"] = function(_)
			return vim.fn.expand("%:e")
		end,
		["${relativeFile}"] = function(_)
			return vim.fn.expand("%:.")
		end,
		["${relativeFileDirname}"] = function(_)
			return vim.fn.fnamemodify(vim.fn.expand("%:.:h"), ":r")
		end,
		["${workspaceFolder}"] = function(_)
			return vim.fn.getcwd()
		end,
		["${workspaceFolderBasename}"] = function(_)
			return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
		end,
		["${env:([%w_]+)}"] = function(match)
			return os.getenv(match) or ""
		end,
	}

	if final_config.envFile then
		local filePath = final_config.envFile
		for key, fn in pairs(placeholders) do
			filePath = filePath:gsub(key, fn)
		end

		for line in io.lines(filePath) do
			local words = {}
			for word in string.gmatch(line, "[^=]+") do
				table.insert(words, word)
			end
			print(vim.inspect(words))
			if not final_config.env then
				final_config.env = {}
			end
			final_config.env[words[1]] = words[2]
		end
	end

	on_config(final_config)
end

dap.adapters.python = function(cb, config)
	if config.request == "attach" then
		---@diagnostic disable-next-line: undefined-field
		local port = (config.connect or config).port
		---@diagnostic disable-next-line: undefined-field
		local host = (config.connect or config).host or "127.0.0.1"
		cb({
			type = "server",
			port = assert(port, "`connect.port` is required for a python `attach` configuration"),
			host = host,
			options = {
				source_filetype = "python",
			},
		})
	else
		cb({
			type = "executable",
			command = "/home/aliyss/.virtualenvs/debugpy/bin/python",
			args = { "-m", "debugpy.adapter" },
			options = {
				source_filetype = "python",
			},
			enrich_config = enrich_config,
		})
	end
end

dap.adapters.delve = function(cb, config)
	if config.mode == "remote" and config.request == "attach" then
		cb({
			type = "server",
			host = config.host or "127.0.0.1",
			port = config.port or "38697",
		})
	else
		cb({
			type = "server",
			port = "${port}",
			executable = {
				command = "dlv",
				args = { "dap", "-l", "127.0.0.1:${port}", "--log", "--log-output=dap" },
				detached = vim.fn.has("win32") == 0,
			},
		})
	end
end

dap.configurations.go = {
	{
		type = "delve",
		name = "Debug",
		request = "launch",
		program = "${file}",
	},
	{
		type = "delve",
		name = "Debug test", -- configuration for debugging test files
		request = "launch",
		mode = "test",
		program = "${file}",
	},
	-- works with go.mod packages and sub packages
	{
		type = "delve",
		name = "Debug test (go.mod)",
		request = "launch",
		mode = "test",
		program = "./${relativeFileDirname}",
	},
}

dap.defaults.fallback.force_external_terminal = true
