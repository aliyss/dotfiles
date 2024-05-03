require("dashboard").setup({
	config = {
		shortcut = {
			{
				icon = "󱔗 ",
				icon_hl = "Label",
				desc = "Files",
				group = "Label",
				action = "Telescope find_files",
				key = "f",
			},
			{
				icon = " ",
				icon_hl = "Number",
				desc = "dotfiles",
				group = "Number",
				action = "Telescope find_files",
				key = "c",
			},
		},
		packages = { enable = false },
		footer = {},
	},
	preview = {
		-- command = "lolcrab",
		file_path = "~/.config/flake/home-manager/apps/neovim/theme/header.txt",
		file_width = 60,
		file_height = 10,
	},
})
