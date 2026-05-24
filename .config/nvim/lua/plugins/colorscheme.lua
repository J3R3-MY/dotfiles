return {
  --Tokyo night
  -- {
  --   "folke/tokyonight.nvim",
  --   priority = 1000,
  --   lazy = false,
  --   config = function()
  --     require("tokyonight").setup()
  --     vim.cmd("colorscheme tokyonight-night")
  --   end,
  -- },
  -- {
  --     'maxmx03/fluoromachine.nvim',
  --     lazy = false,
  --     priority = 1000,
  --     config = function ()
  --      local fm = require 'fluoromachine'
  --
  --      fm.setup {
  --         glow = false,
  --         theme = 'delta',
  --         transparent = true,
  --      }
  --
  --      vim.cmd.colorscheme 'fluoromachine'
  --     end
  -- },
  -- Everforest
  {
    "neanias/everforest-nvim",
    version = false,
    lazy = false,
    priority = 1000, -- make sure to load this before all the other start plugins
    -- Optional; default configuration will be used if setup isn't called.
    config = function()
      require("everforest").setup({
        transparent_background_level = 2,
      })
      vim.cmd.colorscheme 'everforest'
    end,
  }
  -- Bamboo
  -- {
  --   'ribru17/bamboo.nvim',
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     require('bamboo').setup {
  --       -- optional configuration here
  --     }
  --     require('bamboo').load()
  --   end,
  -- },
}
