-- Default LSP servers with minimal config
vim.lsp.enable({ "lua_ls", "dockerls", "bashls", "jsonls" })

-- Taplo (TOML) — provide Cargo.toml schema so taplo doesn't show "excluded" diagnostic
vim.lsp.config("taplo", {
    settings = {
        taplo = {
            schema = {
                associations = {
                    ["Cargo\\.toml$"] = "https://json.schemastore.org/cargo.json",
                },
            },
        },
    },
})
vim.lsp.enable("taplo")
