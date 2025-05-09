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
-- opts.desc = "Copy absolute path"
keymap.set("n", "<leader>--", vim.cmd.Cppath)

-- opts.desc = "Hide Diagnostics"
vim.keymap.set("n", "<leader>hd", ":lua vim.diagnostic.hide()<CR>")
-- opts.desc = "Show Diagnostics"
vim.keymap.set("n", "<leader>sh", ":lua vim.diagnostic.show()<CR>")

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false -- clean-up search

vim.opt.tabstop = 2 -- number of visual spaces per TAB
vim.opt.shiftwidth = 2 -- number of spaces to use for autoindent
--vim.opt.expandtab = true --convert tabs to spaces
-- vim.opt.autoindent = true
vim.opt.copyindent = true -- copy indent from the previous line

vim.opt.showcmd = true --show command in bottom bar

--LSP keymaps
    local keymap = vim.keymap -- for conciseness

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
        keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

        opts.desc = "Show LSP definitions"
        keymap.set("n", "gd", "<cmd>lua Snacks.picker.lsp_definitions()<CR>", opts) -- show lsp definitions

        opts.desc = "Show LSP implementations"
        keymap.set("n", "gi", "<cmd>lua Snacks.picker.lsp_implementations()<CR>", opts) -- show lsp implementations

        opts.desc = "Show LSP type definitions"
        keymap.set("n", "gt", "<cmd>lua Snacks.picker.lsp_type_definitions()<CR>", opts) -- show lsp type definitions

        opts.desc = "See available code actions"
        keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

        opts.desc = "Smart rename"
        keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

        opts.desc = "Show buffer diagnostics"
        keymap.set("n", "<leader>D", "<cmd>lua Snacks.picker.diagnostics_buffer()<CR>", opts) -- show  diagnostics for file

        opts.desc = "Show line diagnostics"
        keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- show diagnostics for line

        opts.desc = "Go to previous diagnostic"
        keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

        opts.desc = "Go to next diagnostic"
        keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

        opts.desc = "Show documentation for what is under cursor"
        keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

        opts.desc = "Restart LSP"
        keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary

     --    opt.desc = "Hide diagnostics for buffer"
    	-- keymap.set("n", "<leader>hd", vim.diagnostic.hide, opts)
      end,
    })

    local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
    end
