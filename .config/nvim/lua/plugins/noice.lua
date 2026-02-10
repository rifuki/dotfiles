return {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
        lsp = {
            override = {
                ["vim.lsp.buf.signature_help"] = false,
                -- ["vim.lsp.buf.hover"] = false,
            },
            signature = { enabled = false },
            -- hover = { enabled = false },
        },
        routes = {
            {
                filter = { event = "notify", find = "No Information Available" },
                opts = { skip = true },
            },
            {
                filter = { event = "msg_show", kind = "error", find = "Invalid offset LineCol" },
                opts = { skip = true },
            },
        },
        presets = {
            lsp_doc_border = true,
        },
    },
    dependencies = {
        "MunifTanjim/nui.nvim",
        "rcarriga/nvim-notify",
    },
}
