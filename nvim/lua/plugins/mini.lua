return {
  'echasnovski/mini.nvim',
  dependencies = { 'JoosepAlviste/nvim-ts-context-commentstring'},
  event = 'VeryLazy',
  config = function()
    require('mini.surround').setup {}
    require('mini.pairs').setup {}
    require('mini.comment').setup {}
    require('mini.icons').setup {}
    require('mini.statusline').setup({
      content = {
        active = function()
          local MiniStatusline = require("mini.statusline")

					local function shorten_string(str, max_length)
						if #str > max_length then
							return string.sub(str, 1, max_length) .. "..."
						else
							return str
						end
					end

          -- Sections from the first configuration
          local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
          local git_og = MiniStatusline.section_git({ trunc_width = 40 })
					local diff = MiniStatusline.section_diff({ trunc_width = 75 })
          local filename = MiniStatusline.section_filename({ trunc_width = 100 })
					local fileinfo = MiniStatusline.section_fileinfo({ trunc_width = 120 })
          local diagnostics = MiniStatusline.section_diagnostics({ trunc_width = 75 })

					local git = shorten_string(git_og, 25)

          return MiniStatusline.combine_groups({
            { hl = mode_hl, strings = { mode:upper() } },
            { hl = "MiniStatuslineDevinfo", strings = { git, diagnostics, diff } },
            "%<", -- Mark general truncate point
            { hl = "MiniStatuslineFilename", strings = { filename} },
            "%=", -- End left alignment
            {
              hl = "MiniStatuslineFileinfo",
              strings = {fileinfo},
            },
            { hl = mode_hl, strings = { "%l:%v" } },
          })
        end,
      },
    })

    local miniclue = require('mini.clue')
    miniclue.setup({
      triggers = {
        -- Leader triggers
        { mode = 'n', keys = '<Leader>' },
        { mode = 'x', keys = '<Leader>' },

        -- Built-in completion
        { mode = 'i', keys = '<C-x>' },

        -- `g` key
        { mode = 'n', keys = 'g' },
        { mode = 'x', keys = 'g' },

        -- Marks
        { mode = 'n', keys = "'" },
        { mode = 'n', keys = '`' },
        { mode = 'x', keys = "'" },
        { mode = 'x', keys = '`' },

        -- Registers
        { mode = 'n', keys = '"' },
        { mode = 'x', keys = '"' },
        { mode = 'i', keys = '<C-r>' },
        { mode = 'c', keys = '<C-r>' },

        -- Window commands
        { mode = 'n', keys = '<C-w>' },

        -- `z` key
        { mode = 'n', keys = 'z' },
        { mode = 'x', keys = 'z' },
      },

      clues = {
        -- Enhance this by adding descriptions for <Leader> mapping groups
        miniclue.gen_clues.builtin_completion(),
        miniclue.gen_clues.g(),
        miniclue.gen_clues.marks(),
        miniclue.gen_clues.registers(),
        miniclue.gen_clues.windows(),
        miniclue.gen_clues.z(),
      },
    })
  end,
}
