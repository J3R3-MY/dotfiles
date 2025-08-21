vim.opt.number = true
vim.opt.relativenumber = true --show line numbers
vim.opt.showmatch = true      --highlight matching brackets
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

keymap.set("n", "<leader>--", vim.cmd.Cppath, { desc = "Copy absolute path of current buffer" })
keymap.set("n", "<leader>cc", "<cmd> NoiceDismiss <CR>", { desc = "Clear notifications" })

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false  -- clean-up search

vim.opt.tabstop = 2       -- number of visual spaces per TAB
vim.opt.shiftwidth = 2    -- number of spaces to use for autoindent
vim.opt.expandtab = true  --convert tabs to spaces
vim.opt.autoindent = true
vim.opt.copyindent = true -- copy indent from the previous line

vim.opt.showcmd = true    --show command in bottom bar

--LSP keymaps
local keymap = vim.keymap     -- for conciseness

local diagnostics_active = true
keymap.set('n', '<leader>td', function()
  diagnostics_active = not diagnostics_active
  if diagnostics_active then
    vim.diagnostic.disable()
  else
    vim.diagnostic.enable()
  end
end, { desc = "Toggle Diagnostics" })

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local opts = { buffer = ev.buf, silent = true }

    -- set keybinds
    opts.desc = "Show LSP references"
    keymap.set("n", "gR", "<cmd>lua Snacks.picker.lsp_references()<CR>", opts) -- show definition, references

    opts.desc = "Go to declaration"
    keymap.set("n", "gD", "<cmd>lua Snacks.picker.lsp_declarations()<CR>", opts)    -- go to declaration

    opts.desc = "Show LSP definitions"
    keymap.set("n", "gd", "<cmd>lua Snacks.picker.lsp_definitions()<CR>", opts)     -- show lsp definitions

    opts.desc = "Show LSP implementations"
    keymap.set("n", "gi", "<cmd>lua Snacks.picker.lsp_implementations()<CR>", opts)     -- show lsp implementations

    opts.desc = "Show LSP type definitions"
    keymap.set("n", "gt", "<cmd>lua Snacks.picker.lsp_type_definitions()<CR>", opts)     -- show lsp type definitions

    opts.desc = "LSP Symbols"
    keymap.set("n", "<leader>gs",
      "<cmd>lua Snacks.picker.lsp_symbols({layout = {preset = 'vscode', preview = 'main'}})<CR>", opts)                             -- show lsp symbols

    opts.desc = "See available code actions"
    keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)     -- see available code actions, in visual mode will apply to selection

    opts.desc = "Smart rename"
    keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)     -- smart rename

    opts.desc = "Show buffer diagnostics"
    keymap.set("n", "<leader>D", "<cmd>lua Snacks.picker.diagnostics_buffer()<CR>", opts)     -- show  diagnostics for file
    opts.desc = "Show line diagnostics"
    keymap.set("n", "<leader>dl", vim.diagnostic.open_float, opts)                            -- show diagnostics for line

    opts.desc = "Show documentation for what is under cursor"
    keymap.set("n", "K", vim.lsp.buf.hover, opts)     -- show documentation for what is under cursor
  end,
})

    keymap.set("n", "<leader>Gd", "<cmd>lua Snacks.picker.git_diff()<CR>", {desc = "Show Git Diff (Hunks)"}) -- show git diff (hunks)

    keymap.set("n", "<leader>Gs", "<cmd>lua Snacks.picker.git_status()<CR>", {desc = "Show Git Status"}) -- show git status

    keymap.set("n", "<leader>C", "<cmd>lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})<CR>", {desc = "Open Config"}) -- open nvim config

    keymap.set("n", "<leader>R", "<cmd>lua Snacks.picker.registers()<CR>", {desc = "Registers"}) -- show registers

    keymap.set("n", "<leader>fs", function()
      require('extensions.snacks-luasnip').open()
    end, {desc = "Find LuaSnip Snippet"})

local signs = { Error = "󰚌", Warn = "󰈸", Hint = " ", Info = "" }
vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = signs.Error,
      [vim.diagnostic.severity.WARN] = signs.Warn,
      [vim.diagnostic.severity.HINT] = signs.Hint,
      [vim.diagnostic.severity.INFO] = signs.Info,
    }
  }
})
