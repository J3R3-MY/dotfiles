return {
  "rachartier/tiny-glimmer.nvim",
  event = "VeryLazy",
  priority = 10,
  opts = {
    overwrite = {
      paste = {
        enabled = true,
        default_animation = "fade", -- change as desired
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
