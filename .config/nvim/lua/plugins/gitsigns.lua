return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns

      local function map(mode, l, r, desc)
        vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
      end

      -- Actions
      map({"n", "v"}, "<leader>hs", ":Gitsigns stage_hunk<CR>", "Stage hunk")
      map({"n", "v"}, "<leader>hr", ":Gitsigns reset_hunk<CR>", "Reset hunk")

      map("n", "<leader>hS", gs.stage_buffer, "Stage buffer")
      map("n", "<leader>hR", gs.reset_buffer, "Reset buffer")

      map({"n", "v"}, "<leader>hu", ":Gitsigns undo_stage_hunk<CR>", "Undo stage hunk")

      map("n", "<leader>hB", gs.toggle_current_line_blame, "Toggle line blame")

      -- Text object
      map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Gitsigns select hunk")
    end,
  },
}
