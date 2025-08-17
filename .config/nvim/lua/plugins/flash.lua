return{
  "folke/flash.nvim",
  event = "VeryLazy",
  ---@type Flash.Config
  opts = {},
  -- stylua: ignore
  keys = {
    { "<leader>s", mode = { "n" }, function() require("flash").jump() end, desc = "Flash" },
    { "<leader>S", mode = { "n" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
  },
}
