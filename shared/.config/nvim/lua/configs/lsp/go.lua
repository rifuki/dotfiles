-- Go LSP. cmd, filetypes and root_dir come from nvim-lspconfig's lsp/gopls.lua;
-- only settings are layered on top.
vim.lsp.config("gopls", {
    settings = {
        gopls = {
            usePlaceholders = true,
            -- `true` is staticcheck's `-checks all`; the ST rules below are the
            -- style checks the CLI's default config leaves off, so the editor
            -- reports what `staticcheck ./...` reports.
            staticcheck = true,
            analyses = {
                ST1000 = false, -- package comment missing
                ST1003 = false, -- initialisms: userId -> userID
                ST1016 = false, -- inconsistent receiver names
                ST1020 = false, -- doc comment on exported func
                ST1021 = false, -- doc comment on exported type
                ST1022 = false, -- doc comment on exported var
            },
        },
    },
})
vim.lsp.enable("gopls")
