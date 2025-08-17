return {
  {
    "lervag/vimtex",
    lazy = false,
    -- tag = "v2.15", -- uncomment to pin to a specific release
    config = function()
      vim.g.vimtex_imaps_enabled = 0
      vim.g.vimtex_view_method =
      'skim' -- change this, depending on what you want to use..sumatraPDF, or skim, or zathura, or...
      vim.g.vimtex_view_general_options = '-reuse-instance -forward-search @tex @line @pdf'
      --quickfix settings
      vim.g.vimtex_quickfix_open_on_warning = 0 --  don't open quickfix if there are only warnings
      vim.g.vimtex_quickfix_ignore_filters = { "Underfull", "Overfull", "LaTeX Warning: .\\+ float specifier changed to",
        "Package hyperref Warning: Token not allowed in a PDF string" }

      -- Text object keymaps

      -- LaTeX commands
      vim.keymap.set({ "o", "x" }, "ac", "<Plug>(vimtex-ac)")
      vim.keymap.set({ "o", "x" }, "ic", "<Plug>(vimtex-ic)")

      -- Paired delimiters
      vim.keymap.set({ "o", "x" }, "ad", "<Plug>(vimtex-ad)")
      vim.keymap.set({ "o", "x" }, "id", "<Plug>(vimtex-id)")

      -- LaTeX environments
      vim.keymap.set({ "o", "x" }, "ae", "<Plug>(vimtex-ae)")
      vim.keymap.set({ "o", "x" }, "ie", "<Plug>(vimtex-ie)")

      -- Inline math
      vim.keymap.set({ "o", "x" }, "a$", "<Plug>(vimtex-a$)")
      vim.keymap.set({ "o", "x" }, "i$", "<Plug>(vimtex-i$)")

      -- Sections
      vim.keymap.set({ "o", "x" }, "aP", "<Plug>(vimtex-aP)")
      vim.keymap.set({ "o", "x" }, "iP", "<Plug>(vimtex-iP)")

      -- Items in itemize and enumerate environments
      vim.keymap.set({ "o", "x" }, "am", "<Plug>(vimtex-am)")
      vim.keymap.set({ "o", "x" }, "im", "<Plug>(vimtex-im)")

      vim.keymap.set("n", "<localleader>V", "<Plug>(vimtex-view)")
    end,
  },
}
