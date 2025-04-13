return {
    {
        "saghen/blink.compat",
        -- use the latest release, via version = '*', if you also use the latest release for blink.cmp
        version = "*",
        -- lazy.nvim will automatically load the plugin when it's required by blink.cmp
        lazy = true,
        -- make sure to set opts so that lazy.nvim calls blink.compat's setup
        opts = {},
    },
    {
        "saghen/blink.cmp",
        -- optional: provides snippets for the snippet source
        dependencies = {
            "rafamadriz/friendly-snippets",
        },

        -- use a release tag to download pre-built binaries
        version = "1.*",
        opts = {
            keymap = {
                preset = "default",
                ["<C-Z>"] = { "accept", "fallback" },
            },

            appearance = {
                nerd_font_variant = "mono",
            },

            completion = { documentation = { auto_show = true } },
            signature = { enabled = true },

            sources = {
                default = { "lsp", "path", "snippets", "buffer"},
            },
        },
        opts_extend = { "sources.default" },
    },
}
