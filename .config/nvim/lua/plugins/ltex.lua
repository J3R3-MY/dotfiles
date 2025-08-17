return {
  "barreiroleo/ltex_extra.nvim",

  opts = {
    load_langs = { "en-US" },
    -- save to .ltex dir
    path = ".ltex",
  },

  config = function(_, opts)
    -- Ltex LSP
    vim.lsp.config.ltex_plus = {
      cmd = { "ltex-ls-plus" },
      filetypes = { "markdown", "tex", "latex", "text" },
      root_markers = {
        ".git",
        vim.uv.cwd()
      },
      on_attach = function()
        require("ltex_extra").setup(opts)
      end,
      settings = {
        ltex = {
          checkFrequency = 'save',
          enabled = { 'markdown', 'tex', 'latex', 'text' },
          language = 'en-US',
        },
      },
    }
    vim.lsp.enable("ltex_plus")
  end,
}

