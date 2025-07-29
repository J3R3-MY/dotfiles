return {
  --Tokyo night
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    lazy = false,
    config = function()
      require("tokyonight").setup()
      vim.cmd("colorscheme tokyonight-night")
    end,
  },
  -- Vague
  -- {
  --   "vague2k/vague.nvim",
  --   priority = 1000,
  --   lazy = false,
  --   config = function()
  --     require("vague").setup({
  --       -- optional configuration here
  --     })
  --   end
  -- },
  -- Onenord
  -- {
  -- 'rmehri01/onenord.nvim',
  --   priority = 1000,
  --   lazy = false,
  --   config = function()
  --     require("onenord").setup({
  --       -- optional configuration here
  --     })
  --   end
  -- },
  -- Bamboo
  -- {
  --   'ribru17/bamboo.nvim',
  --   priority = 1000,
  --   lazy = false,
  --   config = function()
  --     require('bamboo').setup {
  --       -- optional configuration here
  --     }
  --   end,
  -- },
}
