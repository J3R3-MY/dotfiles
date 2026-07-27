return {
  "williamboman/mason.nvim",
  dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		-- JSON/YAML schema catalog, wired into jsonls + yamlls in init.lua
		{ "b0o/SchemaStore.nvim", lazy = true },
  },
  config = function()
    -- import mason
    local mason = require("mason")

    -- import mason-lspconfig
    local mason_lspconfig = require("mason-lspconfig")

    local mason_tool_installer = require("mason-tool-installer")

    -- enable mason and configure icons
    mason.setup({
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    })

    mason_lspconfig.setup({
      -- list of servers for mason to install
      ensure_installed = {
        "clangd",
        "ty",
        "ruff",
        "lua_ls",
        -- "ltex_plus",
        "json-lsp",
        -- DevOps
        "yamlls",
        "dockerls",
        "bashls",
        "terraformls",
        "helm_ls",
        "ansiblels",
        "taplo",
      },
    })

    mason_tool_installer.setup({
      ensure_installed = {
        "codelldb",
        -- DevOps CLIs: linters + formatters
        "shellcheck",
        "shfmt",
        "hadolint",
        "yamllint",
        "actionlint",
        "tflint",
        "prettierd",
      },
    })
  end,
}
