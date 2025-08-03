return {
  "rachartier/tiny-glimmer.nvim",
  event = "VeryLazy",
  priority = 10,
  opts = {
    overwrite = {
      paste = {
        enabled = false,
      },
      yank = {
        enabled = true,
        default_animation = "fade", -- change as desired
      },
      undo = {
        enabled = true,
      },
      redo = {
        enabled = true,
      },
    },
  },
}
