return {
    -- Disable NvChad's cmp-async-path (Codeberg blocks Tencent Cloud IPs;
    -- cmp-path below covers the same use case)
    { "https://codeberg.org/FelipeLema/cmp-async-path.git", enabled = false },

    -- nvim-cmp completion engine
    {
        "hrsh7th/nvim-cmp",
        opts = function(_, opts)
            opts.sources = opts.sources or {}
            table.insert(opts.sources, { name = "nvim_lsp" })
        end,
    },

    -- Command line completion
    {
        "hrsh7th/cmp-cmdline",
        lazy = false,
        dependencies = {
            "hrsh7th/nvim-cmp",
            "hrsh7th/cmp-path",
        },
        config = function()
            local cmp = require("cmp")

            -- Search completion (/)
            cmp.setup.cmdline("/", {
                mapping = cmp.mapping.preset.cmdline(),
                sources = {
                    { name = "buffer" },
                },
            })

            -- Command completion (:)
            cmp.setup.cmdline(":", {
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources({
                    { name = "path" },
                }, {
                    {
                        name = "cmdline",
                        option = {
                            ignore_cmds = { "Man", "!" },
                        },
                    },
                }),
            })
        end,
    },
}
