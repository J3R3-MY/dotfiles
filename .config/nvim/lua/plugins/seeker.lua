return {
  '2kabhishek/seeker.nvim',
  dependencies = { 'folke/snacks.nvim' },
  cmd = { 'Seeker' },
  keys = {
    { '<leader>ff', ':Seeker files<CR>', desc = 'Seek Files' },
    { '<leader>fg', ':Seeker grep<CR>',  desc = 'Seek Grep' },
  },
  config = function()
    require('seeker').setup({
      toggle_key = '<C-r>', -- Key to toggle between modes (default)
      picker_opts = {}, -- Options passed to snacks.picker (optional)
    })
  end,
}
