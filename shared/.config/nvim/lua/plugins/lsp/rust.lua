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

                    -- Check if this is an Anchor project
                    local cwd = client.config.root_dir or vim.fn.getcwd()
                    local is_anchor = vim.fn.filereadable(cwd .. "/Anchor.toml") == 1

                    if is_anchor then
                        -- For Anchor projects, notify user about expected false positives
                        vim.notify(
                            "Anchor project detected. Some macro diagnostics may be false positives.",
                            vim.log.levels.INFO,
                            { title = "rust-analyzer" }
                        )
                    end
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
                        -- IMPORTANT: checkOnSave always enabled for typo detection!
                        checkOnSave = {
                            enable = true,
                            command = "clippy",
                        },
                    },
                },
            },
        }
    end,
}
