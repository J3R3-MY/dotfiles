return {
   "nvim-lualine/lualine.nvim",
   dependencies = { "nvim-tree/nvim-web-devicons" },
   config = function()
     local lualine = require("lualine")
     local lazy_status = require("lazy.status") -- to configure lazy pending updates count
     lualine.setup({
       options = {
         theme = 'auto',
       },
       sections = {
       	lualine_a = { "mode" },
       	lualine_b = { { "branch", fmt = function(str) return str:sub(1,16) end }},
       	lualine_c = { "filename",
					{
            function()
              local reg = vim.fn.reg_recording()
              return ' recording to ' .. reg
            end,
            color = 'DiagnosticError',
            cond = function()
              return vim.fn.reg_recording() ~= ''
            end,
          },
       	},
        lualine_x = {
           {
             lazy_status.updates,
             cond = lazy_status.has_updates,
             color = { fg = "#ff9e64" },
           },
           { "encoding" },
           { "fileformat" },
           { "filetype" }, 
         },
       },
     })
   end,
 }
