return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>F",
      function()
        require("conform").format({ async = true })
      end,
      mode = { "v", "n" },
      desc = "Format",
    },
  },
  opts = {
    -- Define formatters
    formatters_by_ft = {
      lua = { "stylua" },
      cpp = { "clang-format" },
      sh = { "shfmt" },
      bash = { "shfmt" },
      yaml = { "prettierd" },
      json = { "prettierd" },
      jsonc = { "prettierd" },
      markdown = { "prettierd" },
      terraform = { "terraform_fmt" },
      hcl = { "terraform_fmt" },
    },
    -- Set default options
    default_format_opts = {
      lsp_format = "fallback",
    },
    -- Custom formatters
    formatters = {
      clang_format = {
        prepend_args = { '--style=file', '--fallback-style=LLVM' },
      }
    },
  },
  init = function()
  end,
}
