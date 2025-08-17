return {
  "chrisgrieser/nvim-scissors",
  dependencies = "folke/snacks.nvim",
  config = function()
    require("scissors").setup({
      snippetDir = vim.fn.stdpath("config") .. "/snippets/vscode",
    })
  end,
}
