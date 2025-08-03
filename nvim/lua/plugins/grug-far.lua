return {
  "MagicDuck/grug-far.nvim",
  opts = { headerMaxWidth = 80 },
  cmd = "GrugFar",
  keys = {
    {
      "<leader>gf",
      function()
        local grug = require("grug-far")
        local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
        grug.open({
          transient = true,
          prefills = {
            filesFilter = ext and ext ~= "" and "*." .. ext or nil,
          },
        })
      end,
      mode = { "n" },
      desc = "GrugFar",
    },
    vim.keymap.set({ 'v', 'x' }, '<leader>gf', function()
      require('grug-far').open({ visualSelectionUsage = 'operate-within-range' })
    end, { desc = 'GrugFarWithin' })
  },
}
