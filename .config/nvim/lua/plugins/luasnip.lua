return {
  "L3MON4D3/LuaSnip",
  version = "v2.*",
  build = "make install_jsregexp",
  event = "InsertEnter",
  dependencies = {
    {
      "rafamadriz/friendly-snippets",
      config = function()
        require("luasnip.loaders.from_vscode").lazy_load()
        require("luasnip.loaders.from_vscode").lazy_load({ paths = { vim.fn.stdpath("config") .. "/snippets/vscode" } })
        require("luasnip.loaders.from_lua").lazy_load({ paths = { vim.fn.stdpath("config") .. "/snippets/luasnip" } })
      end,
    },
  },
  config = function()
    local ls = require("luasnip")
    ls.setup({
      update_events = { "TextChanged", "TextChangedI" },
      enable_autosnippets = true,
    })
    vim.keymap.set({ "i", "s" }, "<C-n>", function()
      if ls.expand_or_jumpable() then
        ls.expand_or_jump()
      end
    end, { silent = true, desc = "Expand current snippet or jump to next" })

    vim.keymap.set({ "i", "s" }, "<C-p>", function()
      if ls.jumpable(-1) then
        ls.jump(-1)
      end
    end, { silent = true, desc = "Go to previous snippet" })
  end
}
