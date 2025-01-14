return {
  "nvzone/menu",
  dependencies = {
    "nvzone/volt",
  },
	-- Mouse users + nvimtree users!
	vim.keymap.set({ "n", "v" }, "<RightMouse>", function()
	  require('menu.utils').delete_old_menus()

	  vim.cmd.exec '"normal! \\<RightMouse>"'
	
		local normal_buffer = require("core.menus.menu_default")
		local nvimtree_buffer = require("core.menus.menu_nvimtree")
	  -- clicked buf
	  local buf = vim.api.nvim_win_get_buf(vim.fn.getmousepos().winid)
	  if vim.bo[buf].ft == "NvimTree" then
		local options = "nvimtree"
		require("menu").open(nvimtree_buffer, { mouse = true })
	  else -- Normal buffer case
    	require("menu").open(normal_buffer, { mouse = true })
  		end
	end, {})
}
