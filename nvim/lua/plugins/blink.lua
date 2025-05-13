return {
	{
		"saghen/blink.compat",
		-- use the latest release, via version = '*', if you also use the latest release for blink.cmp
		version = "*",
		-- lazy.nvim will automatically load the plugin when it's required by blink.cmp
		lazy = true,
		-- make sure to set opts so that lazy.nvim calls blink.compat's setup
		opts = {},
	},
	{
		"saghen/blink.cmp",
		dependencies = {
			"rafamadriz/friendly-snippets",
			"giuxtaposition/blink-cmp-copilot"
		},

		-- use a release tag to download pre-built binaries
		version = "1.*",
		opts = {
			keymap = {
				preset = "enter",
				["<C-j>"] = { "show", "select_next", "fallback" },
				["<C-k>"] = { "show", "select_prev", "fallback" },
			},

			completion = { documentation = { auto_show = true } },
			signature = { enabled = true },

			cmdline = {
				keymap = { preset = 'inherit' },
				completion = { menu = { auto_show = false } },
			},

			sources = {
				default = { "lsp", "path", "snippets", "buffer", "copilot" },
				providers = {
					copilot = {
						name = "copilot",
						module = "blink-cmp-copilot",
						score_offset = 100,
						async = true,
						transform_items = function(_, items)
							for _, item in ipairs(items) do
								item.kind_icon = ""
								item.kind_name = "Copilot"
							end
							return items
						end,
					},
				},
			},
		},
	}
}
