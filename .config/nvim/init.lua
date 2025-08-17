require("core.keymap")
require("core.lazy")


--C++ {{{
vim.lsp.config.clangd = {
	cmd = { "clangd", "--background-index" },
	filetypes = { "c", "cpp", "cc", "cxx", "h", "hpp", "hxx" },
	root_markers = {
		".clangd",
		".git",
		"compile_commands.json",
		vim.uv.cwd()
	},
}
vim.lsp.enable("clangd")
-- }}}

-- Lua {{{
vim.lsp.config.lua_ls = {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	root_markers = {
		".luarc.json",
		".git",
		vim.uv.cwd() },
	settings = {
		Lua = {
			telemetry = {
				enable = false,
			},
		},
	},
}
vim.lsp.enable("lua_ls")
-- }}}

-- Ltex LSP
-- vim.lsp.config.ltex_plus = {
--   cmd = { "ltex-ls-plus" },
--   filetypes = { "markdown", "tex", "latex", "text" },
--   root_markers = {
--     ".git",
--     vim.uv.cwd()
--   },
--   settings = {
--     ltex = {
--       checkFrequency = 'save',
--       enabled = { 'markdown', 'tex', 'latex', 'text' },
--       language = 'en-US',
--     },
--   },
-- }
-- vim.lsp.enable("ltex_plus")

-- Python {{{
vim.lsp.config.basedpyright = {
	name = "basedpyright",
	filetypes = { "python" },
	cmd = { "basedpyright-langserver", "--stdio" },
	root_markers = {
		"pyproject.toml",
		"setup.py",
		"setup.cfg",
		"requirements.txt",
		"Pipfile",
		"pyrightconfig.json",
		".git",
		vim.uv.cwd(),
	},
	settings = {
		basedpyright = {
			disableOrganizeImports = true,
			analysis = {
				-- Use ruff for linting
				ignore = { '*' },
				-- autoSearchPaths = true,
				-- autoImportCompletions = true,
				-- useLibraryCodeForTypes = true,
				-- diagnosticMode = "openFilesOnly",
				-- typeCheckingMode = "basic",
				-- inlayHints = {
				--   variableTypes = true,
				--   callArgumentNames = true,
				--   functionReturnTypes = true,
				--   genericTypes = false,
				-- },
			},
		},
	},
}
vim.lsp.enable("basedpyright")


vim.lsp.config('ruff', {
	name = "ruff",
	filetypes = { "python" },
	cmd = { "ruff", "server" },
	root_markers = {
		"pyproject.toml",
		"setup.py",
		"setup.cfg",
		"requirements.txt",
		"Pipfile",
		"pyrightconfig.json",
		".git",
		vim.uv.cwd(),
	},
	init_options = {
		settings = {
			logLevel = 'debug',
			lineLength = 120,
			showSyntaxErrors = true,
			lint = {
				ignore = { "E4", "E7" }
			}
		}
	}
})

vim.lsp.enable('ruff')

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup('lsp_attach_disable_ruff_hover', { clear = true }),
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client == nil then
			return
		end
		if client.name == 'ruff' then
			-- Disable hover in favor of Pyright
			client.server_capabilities.hoverProvider = false
		end
	end,
	desc = 'LSP: Disable hover capability from Ruff',
})
-- }}}


vim.opt.foldlevel = 99
