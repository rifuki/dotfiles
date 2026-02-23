return {
    "mrcjkb/rustaceanvim",
    version = "^5",
    lazy = false,
    config = function()
        -- Auto-install rust-analyzer component if missing
        vim.fn.jobstart({ "rustup", "component", "list", "--installed" }, {
            stdout_buffered = true,
            on_stdout = function(_, data)
                local output = table.concat(data, "\n")
                if not output:find("rust%-analyzer") then
                    vim.notify("Installing rust-analyzer via rustup...", vim.log.levels.INFO)
                    vim.fn.jobstart({ "rustup", "component", "add", "rust-analyzer" }, {
                        on_exit = function(_, code)
                            if code == 0 then
                                vim.notify("rust-analyzer installed! Restart Neovim.", vim.log.levels.INFO)
                            end
                        end,
                    })
                end
            end,
        })
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
                        files = {
                            excludeDirs = {},
                            watcher = "client",
                        },
                    },
                },
            },
        }
    end,
}
