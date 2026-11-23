-- JSON LSP with schemas for tsconfig.json, package.json, etc.
vim.lsp.config("jsonls", {
    settings = {
        json = {
            schemas = {
                -- TypeScript config schemas
                {
                    fileMatch = { "tsconfig.json", "tsconfig.*.json" },
                    url = "https://json.schemastore.org/tsconfig.json",
                },
                -- Package.json schema
                {
                    fileMatch = { "package.json" },
                    url = "https://json.schemastore.org/package.json",
                },
                -- ESLint config schemas
                {
                    fileMatch = { ".eslintrc.json", ".eslintrc" },
                    url = "https://json.schemastore.org/eslintrc.json",
                },
                -- Prettier config
                {
                    fileMatch = { ".prettierrc", ".prettierrc.json", "prettier.config.json" },
                    url = "https://json.schemastore.org/prettierrc.json",
                },
                -- VSCode settings
                {
                    fileMatch = { ".vscode/settings.json" },
                    url = "https://json.schemastore.org/vscode-settings.json",
                },
                -- Next.js config
                {
                    fileMatch = { "next.config.json" },
                    url = "https://json.schemastore.org/next.json",
                },
            },
            validate = { enable = true },
            completion = true,
            hover = true,
            -- Use schema store for everything else (auto-detect)
            schemaDownload = { enable = true },
        },
    },
})

-- Default LSP servers with minimal config
vim.lsp.enable({ "lua_ls", "dockerls", "bashls", "jsonls" })

-- TOML: tombi instead of taplo. taplo 0.10 returns no completion for a half-typed key inside
-- [[bin]]-style tables and cannot read SchemaStore's catalog; tombi resolves Cargo.toml,
-- .cargo/config.toml and rust-toolchain.toml schemas on its own and flags unknown keys.
vim.lsp.enable("tombi")
