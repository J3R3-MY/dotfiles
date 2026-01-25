return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	---@type snacks.Config
	opts = {
		dashboard = {
      preset = {
        keys = {
          { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
          { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
          { icon = " ", key = "s", desc = "Restore Session", section = "session" },
          { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
        header = [[
███╗   ██╗ ██████╗ ████████╗    ██╗   ██╗███████╗     ██████╗ ██████╗ ██████╗ ███████╗
████╗  ██║██╔═══██╗╚══██╔══╝    ██║   ██║██╔════╝    ██╔════╝██╔═══██╗██╔══██╗██╔════╝
██╔██╗ ██║██║   ██║   ██║       ██║   ██║███████╗    ██║     ██║   ██║██║  ██║█████╗  
██║╚██╗██║██║   ██║   ██║       ╚██╗ ██╔╝╚════██║    ██║     ██║   ██║██║  ██║██╔══╝  
██║ ╚████║╚██████╔╝   ██║        ╚████╔╝ ███████║    ╚██████╗╚██████╔╝██████╔╝███████╗
╚═╝  ╚═══╝ ╚═════╝    ╚═╝         ╚═══╝  ╚══════╝     ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝
          ]]
      },
			sections = {
				{ section = "header" },
				{ section = "keys",   gap = 1, padding = 1 },
				{ section = "startup" },
			},
		},
		notifier = {
			enabled = true,
		},
		scroll = {
		  enabled = true,
		  easing = "quadratic",
		},
		indent = {
			enabled = true,
			priority = 1,
			char = "│",
			only_scope = false,
			only_current = false,
			hl = "SnacksIndent",
			animate = {
				enabled = vim.fn.has("nvim-0.10") == 1,
				style = "out",
				easing = "linear",
				duration = {
					step = 20,
					total = 500,
				},
			},
			scope = {
				enabled = true,
				priority = 200,
				char = "│",
				underline = false,
				only_current = false,
				hl = "SnacksIndentScope",
			},
			chunk = {
				enabled = false,
				only_current = false,
				priority = 200,
				hl = "SnacksIndentChunk",
				char = {
					corner_top = "┌",
					corner_bottom = "└",
					horizontal = "─",
					vertical = "│",
					arrow = ">",
				},
			},
			filter = function(buf)
				return vim.g.snacks_indent ~= false and vim.b[buf].snacks_indent ~= false and vim.bo[buf].buftype == ""
			end,
		},
		explorer = {},
		picker = {
			layout = {
				preset = "telescope",
			},
			sources = {
				explorer = {
					exclude = { ".DS_Store" },
				},
			},
		},
	},
	keys = {
		-- { "<leader>ff", function() Snacks.picker.smart() end,         desc = "Find Files" },
		{ "<leader>fr", function() Snacks.picker.recent() end,        desc = "Recent Files" },
		-- { "<leader>fg", function() Snacks.picker.grep() end,          desc = "Live Grep" },
		{ "<leader>fw", function() Snacks.picker.grep_word() end,     desc = "Find String under Cursor", mode = { "n", "x" } },
		{ "<leader>ee", function() Snacks.picker.explorer() end,      desc = "Toggle Filetree" },
		{ "<leader>lg", function() Snacks.lazygit.open() end,         desc = "LazyGit" },
		{ "<leader>n",  function() Snacks.picker.notifications() end, desc = "Notification History" },
	},
}
