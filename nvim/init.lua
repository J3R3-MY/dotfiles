require ("core.keymap")
require ("core.lazy")


--C++ {{{
vim.lsp.config.clangd = {
	cmd = { "clangd", "--background-index" },
	filetypes = { "c", "cpp", "cc", "cxx", "h", "hpp", "hxx" },
	root_markers = {
		".clangd",
		".git",
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
        autoSearchPaths = true,
        autoImportCompletions = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "openFilesOnly",
        typeCheckingMode = "basic",
        inlayHints = {
          variableTypes = true,
          callArgumentNames = true,
          functionReturnTypes = true,
          genericTypes = false,
        },
      },
    },
  },
}
vim.lsp.enable("basedpyright")
-- }}}


vim.opt.foldlevel = 99
