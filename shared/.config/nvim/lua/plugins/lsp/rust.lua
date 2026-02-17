return {
    "mrcjkb/rustaceanvim",
    version = "^5",
    lazy = false,
    config = function()
        vim.g.rustaceanvim = {
            server = {
                on_attach = function(client, bufnr)
                    -- Disable inlay hints by default (can be toggled)
                    vim.lsp.inlay_hint.enable(false)
                end,
                default_settings = {
                    ["rust-analyzer"] = {
                        cargo = {
                            allFeatures = true,
                            buildScripts = {
                                enable = true,
                            },
                        },
                        procMacro = {
                            enable = true,
                            attributes = {
                                enable = true,
                            },
                        },
                        diagnostics = {
                            disabled = {
                                "unresolved-proc-macro",
                                "unresolved-macro-call",
                            },
                        },
                    },
                },
            },
        }
    end,
}
