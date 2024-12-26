vim.opt.number = true
vim.opt.relativenumber = true --show line numbers
vim.opt.showmatch = true --highlight matching brackets
vim.opt.laststatus = 2

vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.clipboard = 'unnamedplus'
vim.opt.mouse = 'a'

vim.api.nvim_create_user_command("Cppath", function()
    local path = vim.fn.expand("%:p")
    vim.fn.setreg("+", path)
    vim.notify('Copied "' .. path .. '" to the clipboard!')
end, {})

local keymap = vim.keymap
keymap.set("n", "<leader>--", vim.cmd.Cppath)

vim.keymap.set("n", "<leader>hd", ":lua vim.diagnostic.hide()<CR>")
vim.keymap.set("n", "<leader>sh", ":lua vim.diagnostic.show()<CR>")

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false -- clean-up search

vim.opt.tabstop = 4 -- number of visual spaces per TAB
vim.opt.shiftwidth = 4 -- number of spaces to use for autoindent
--vim.opt.expandtab = true --convert tabs to spaces
--vim.opt.autoindent = true
vim.opt.copyindent = true -- copy indent from the previous line

vim.opt.showcmd = true --show command in bottom bar

