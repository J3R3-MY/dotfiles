return {
  {
    "micangl/cmp-vimtex",
    ft = "tex",
    config = function()
      require('cmp_vimtex').setup({})
    end,
  },
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
      "giuxtaposition/blink-cmp-copilot",
      "L3MON4D3/LuaSnip",
      "archie-judd/blink-cmp-words"
		},

		-- use a release tag to download pre-built binaries
		version = "1.*",
		opts = {
			fuzzy = {
				implementation = "prefer_rust_with_warning"
			},
			keymap = {
				preset = "enter",
				["<C-j>"] = { "show", "select_next", "fallback" },
        ["<C-k>"] = { "show", "select_prev", "fallback" },
      },

			completion = { documentation = { auto_show = true } },
      signature = {
        enabled = true,
        window = {
          show_documentation = false
        }
      },
      snippets = { preset = 'luasnip' },

			cmdline = {
				keymap = { preset = 'inherit' },
				completion = {
					menu = { auto_show = false },
					ghost_text = { enabled = false },
				},
			},
			sources = {
        default = { "lsp", "path", "snippets", "buffer", "copilot" },

        per_filetype = {
          lua = { inherit_defaults = true },
          cpp = { inherit_defaults = true },
          c = { inherit_defaults = true },
          python = { inherit_defaults = true },
          tex = { inherit_defaults = true, "thesaurus", "dictionary", "vimtex"},
          markdown = { inherit_defaults = true, "thesaurus", "dictionary" },
          text = { inherit_defaults = true, "thesaurus", "dictionary" },
        },
				providers = {
				  lsp = {
				    score_offset = 4,
				  },
				  snippets = {
				    score_offset = 2,
            opts = {
              show_autosnippets = false,
            },
				  },
          vimtex = {
            name = 'vimtex',
            module = 'blink.compat.source',
            score_offset = 20,
          },
					copilot = {
						name = "copilot",
						module = "blink-cmp-copilot",
						score_offset = 0,
						async = true,
						transform_items = function(_, items)
							for _, item in ipairs(items) do
								item.kind_icon = " "
								item.kind_name = "Copilot"
							end
							return items
						end,
					},
          thesaurus = {
            name = "blink-cmp-words",
            module = "blink-cmp-words.thesaurus",
            opts = {
              score_offset = 0,
              -- Default pointers define the lexical relations listed under each definition,
              -- see Pointer Symbols below.
              -- Default is as below ("antonyms", "similar to" and "also see").
              pointer_symbols = { "!", "&", "^" },
            },
          },
          dictionary = {
            name = "blink-cmp-words",
            module = "blink-cmp-words.dictionary",
            opts = {
              -- The number of characters required to trigger completion.
              -- Set this higher if completion is slow, 3 is default.
              dictionary_search_threshold = 3,
              score_offset = 0,
              pointer_symbols = { "!", "&", "^" },
            },
          },
        },
      },
		},
	}
}
