return {
    "hrsh7th/cmp-cmdline",
    lazy = false,
    dependencies = {
        "hrsh7th/nvim-cmp",
        "hrsh7th/cmp-path", -- Additional: for autocomplete path
        "hrsh7th/cmp-cmdline", -- Additional: for autocomplete command mode
    },
    config = function()
        local cmp = require("cmp")

        cmp.setup.cmdline("/", {
            mapping = cmp.mapping.preset.cmdline(),
            sources = {
                { name = "buffer" },
            },
        })
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
}
