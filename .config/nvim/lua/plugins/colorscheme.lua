-- Linux (fluid desktop): colours made from the wallpaper by matugen
-- (~/.local/state/fluid/nvim-colors.lua, written by fluid-theme.sh), applied
-- with mini.base16 and re-applied in every running Neovim when the theme
-- changes. Without that file (Mac, no theme yet): everforest.
local fluid = vim.fn.expand("~/.local/state/fluid/nvim-colors.lua")

local function apply_fluid()
  if vim.fn.has("linux") == 0 then return false end
  local ok, palette = pcall(dofile, fluid)
  if not ok or type(palette) ~= "table" then return false end
  require("mini.base16").setup({ palette = palette, use_cterm = true })
  vim.g.colors_name = "fluid"
  -- see-through like everforest's transparent_background_level = 2
  for _, group in ipairs({ "Normal", "NormalNC", "SignColumn", "LineNr", "FoldColumn", "EndOfBuffer" }) do
    local hl = vim.api.nvim_get_hl(0, { name = group })
    hl.bg, hl.ctermbg = nil, nil
    vim.api.nvim_set_hl(0, group, hl)
  end
  vim.api.nvim_exec_autocmds("ColorScheme", { pattern = "fluid" }) -- lualine 'auto' follows
  return true
end

-- matugen replaces the file, so watch its folder
local function watch_fluid()
  local w = vim.uv.new_fs_event()
  if not w then return end
  local pending = false
  w:start(vim.fn.fnamemodify(fluid, ":h"), {}, vim.schedule_wrap(function(_, name)
    if name ~= "nvim-colors.lua" or pending then return end
    pending = true
    vim.defer_fn(function() pending = false; apply_fluid() end, 200)
  end))
end

return {
  --Tokyo night
  -- {
  --   "folke/tokyonight.nvim",
  --   priority = 1000,
  --   lazy = false,
  --   config = function()
  --     require("tokyonight").setup()
  --     vim.cmd("colorscheme tokyonight-night")
  --   end,
  -- },
  -- {
  --     'maxmx03/fluoromachine.nvim',
  --     lazy = false,
  --     priority = 1000,
  --     config = function ()
  --      local fm = require 'fluoromachine'
  --
  --      fm.setup {
  --         glow = false,
  --         theme = 'delta',
  --         transparent = true,
  --      }
  --
  --      vim.cmd.colorscheme 'fluoromachine'
  --     end
  -- },
  -- Everforest (fallback), fluid colours on Linux
  {
    "neanias/everforest-nvim",
    version = false,
    lazy = false,
    priority = 1000, -- make sure to load this before all the other start plugins
    -- Optional; default configuration will be used if setup isn't called.
    config = function()
      require("everforest").setup({
        transparent_background_level = 2,
      })
      if apply_fluid() then
        watch_fluid()
      else
        vim.cmd.colorscheme 'everforest'
      end
    end,
  }
  -- Bamboo
  -- {
  --   'ribru17/bamboo.nvim',
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     require('bamboo').setup {
  --       -- optional configuration here
  --     }
  --     require('bamboo').load()
  --   end,
  -- },
}
