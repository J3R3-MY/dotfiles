return {
  "error311/wayfinder.nvim",

  keys = {
    { "<leader>wf",  "<Plug>(WayfinderOpen)",      desc = "Wayfinder" },
    { "<leader>wtn", "<Plug>(WayfinderTrailNext)", desc = "Wayfinder Trail Next" },
    { "<leader>wtp", "<Plug>(WayfinderTrailPrev)", desc = "Wayfinder Trail Prev" },
    { "<leader>wto", "<Plug>(WayfinderTrailOpen)", desc = "Wayfinder Trail Open" },
    { "<leader>wts", "<Plug>(WayfinderTrailShow)", desc = "Wayfinder Trail Show" },
  },

  config = function()
    require("wayfinder").setup({
      performance = "fast",

      scope = {
        mode = "cwd",
      },

      limits = {
        refs = {
          max_results = 200,
          timeout_ms = 1200,
        },

        text = {
          enabled = true,
          max_results = 100,
          timeout_ms = 800,
        },

        tests = {
          max_results = 50,
          timeout_ms = 700,
        },

        git = {
          enabled = true,
          max_commits = 15,
          timeout_ms = 400,
        },
      },
    })
  end,
}
