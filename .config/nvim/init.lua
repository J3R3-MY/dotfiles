-- Ensure cargo-installed CLIs (e.g. tree-sitter, used by nvim-treesitter to
-- compile parsers) are found regardless of how Neovim is launched (GUI apps
-- and non-login shells may not inherit ~/.cargo/bin on PATH).
vim.env.PATH = vim.fn.expand("~/.cargo/bin") .. ":" .. vim.env.PATH

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

-- json {{{
vim.lsp.config.jsonls = {
	cmd = { "vscode-json-language-server", "--stdio" },
	filetypes = { "json", "jsonc" },
	root_markers = {
		".git",
		vim.uv.cwd()
	},
	settings = {
		json = {
			-- SchemaStore catalog: K8s, GitHub Actions, compose, etc.
			schemas = require("schemastore").json.schemas(),
			validate = { enable = true },
		},
	},
}
vim.lsp.enable("jsonls")
-- }}}

-- yaml {{{
vim.lsp.config.yamlls = {
	cmd = { "yaml-language-server", "--stdio" },
	filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab" },
	root_markers = {
		".git",
		vim.uv.cwd()
	},
	settings = {
		yaml = {
			-- Disable the built-in schema store in favor of SchemaStore.nvim
			schemaStore = {
				enable = false,
				url = "",
			},
			schemas = require("schemastore").yaml.schemas(),
			validate = true,
			keyOrdering = false,
		},
	},
}
vim.lsp.enable("yamlls")
-- }}}

-- Docker {{{
vim.lsp.config.dockerls = {
	cmd = { "docker-langserver", "--stdio" },
	filetypes = { "dockerfile" },
	root_markers = {
		"Dockerfile",
		".git",
		vim.uv.cwd()
	},
}
vim.lsp.enable("dockerls")
-- }}}

-- Bash {{{
vim.lsp.config.bashls = {
	cmd = { "bash-language-server", "start" },
	filetypes = { "sh", "bash" },
	root_markers = {
		".git",
		vim.uv.cwd()
	},
}
vim.lsp.enable("bashls")
-- }}}

-- Terraform {{{
vim.lsp.config.terraformls = {
	cmd = { "terraform-ls", "serve" },
	filetypes = { "terraform", "terraform-vars" },
	root_markers = {
		".terraform",
		".git",
		vim.uv.cwd()
	},
}
vim.lsp.enable("terraformls")
-- }}}

-- Helm {{{
vim.lsp.config.helm_ls = {
	cmd = { "helm_ls", "serve" },
	filetypes = { "helm" },
	root_markers = {
		"Chart.yaml",
		".git",
		vim.uv.cwd()
	},
}
vim.lsp.enable("helm_ls")
-- }}}

-- Ansible {{{
vim.lsp.config.ansiblels = {
	cmd = { "ansible-language-server", "--stdio" },
	filetypes = { "yaml.ansible" },
	root_markers = {
		"ansible.cfg",
		".ansible-lint",
		".git",
		vim.uv.cwd()
	},
}
vim.lsp.enable("ansiblels")
-- }}}

-- TOML {{{
vim.lsp.config.taplo = {
	cmd = { "taplo", "lsp", "stdio" },
	filetypes = { "toml" },
	root_markers = {
		".git",
		vim.uv.cwd()
	},
}
vim.lsp.enable("taplo")
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
-- ty: Astral's type checker / language server (replaces basedpyright)
vim.lsp.config.ty = {
	name = "ty",
	filetypes = { "python" },
	cmd = { "ty", "server" },
	root_markers = {
		"ty.toml",
		"pyproject.toml",
		"setup.py",
		"setup.cfg",
		"requirements.txt",
		"Pipfile",
		".git",
		vim.uv.cwd(),
	},
}
vim.lsp.enable("ty")


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
			-- Disable hover in favor of ty
			client.server_capabilities.hoverProvider = false
		end
	end,
	desc = 'LSP: Disable hover capability from Ruff',
})
-- }}}


vim.opt.foldlevel = 99
