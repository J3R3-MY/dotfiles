return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    dashboard = {
      sections = {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },
        { section = "startup" },
      },
    },
    indent = {
      enabled = true,
      priority = 1,
      char = "│",
      only_scope = false,
      only_current = false,
      hl = "SnacksIndent",
      animate = {
        enabled = vim.fn.has("nvim-0.10") == 1,
        style = "out",
        easing = "linear",
        duration = {
          step = 20,
          total = 500,
        },
      },
      scope = {
        enabled = true,
        priority = 200,
        char = "│",
        underline = false,
        only_current = false,
        hl = "SnacksIndentScope",
      },
      chunk = {
        enabled = false,
        only_current = false,
        priority = 200,
        hl = "SnacksIndentChunk",
        char = {
          corner_top = "┌",
          corner_bottom = "└",
          horizontal = "─",
          vertical = "│",
          arrow = ">",
        },
      },
      filter = function(buf)
        return vim.g.snacks_indent ~= false and vim.b[buf].snacks_indent ~= false and vim.bo[buf].buftype == ""
      end,
    },
    explorer ={},
    picker = {
      layout = {
        preset = "telescope",
      },
      sources = {
        explorer = {
          exclude = { ".DS_Store" },
        },
      },
    },
  },
  keys = {
    { "<leader>ff", function() Snacks.picker.files() end, desc = "Find Files" },
    { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent Files" },
    { "<leader>fs", function() Snacks.picker.grep() end, desc = "Live Grep" },
    { "<leader>fc", function() Snacks.picker.grep_word() end, desc = "Find String under Cursor" },
    { "<leader>ee", function() Snacks.picker.explorer() end, desc = "Toggle Filetree" },
    { "<leader>lg", function() Snacks.lazygit.open() end, desc = "LazyGit" },
  },
}


