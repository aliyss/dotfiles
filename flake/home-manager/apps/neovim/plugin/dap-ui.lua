local dap, dapui = require("dap"), require("dapui")

local dapui_config = {
	layouts = {
		{
			-- You can change the order of elements in the sidebar
			elements = {
				-- Provide IDs as strings or tables with "id" and "size" keys
				{
					id = "scopes",
					size = 0.25, -- Can be float or integer > 1
				},
				{ id = "breakpoints", size = 0.25 },
				{ id = "stacks", size = 0.25 },
				{ id = "watches", size = 0.25 },
			},
			size = 40,
			position = "left", -- Can be "left" or "right"
		},
		{
			elements = {
				"repl",
				"console",
			},
			size = 10,
			position = "bottom", -- Can be "bottom" or "top"
		},
		{
			elements = {
				-- Provide IDs as strings or tables with "id" and "size" keys
				{
					id = "repl",
					size = 0.25, -- Can be float or integer > 1
				},
				{ id = "console", size = 0.75 },
			},
			size = 70,
			position = "right", -- Can be "bottom" or "top"
		},
	},
}

dapui.setup(dapui_config)

dap.listeners.before.attach.dapui_config = function()
	dapui.open(1)
	dapui.open(2)
	dapui.close(3)
end

dap.listeners.before.launch.dapui_config = function()
	dapui.close(1)
	dapui.close(2)
	dapui.open(3)
end

dap.listeners.before.event_terminated.dapui_config = function()
	-- dapui.close()
end

dap.listeners.before.event_exited.dapui_config = function()
	-- dapui.close()
end
