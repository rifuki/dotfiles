-- cmd, filetypes and root_dir come from nvim-lspconfig; this file only adds settings.
vim.lsp.config("gopls", {
    settings = {
        gopls = {
            usePlaceholders = true,
            -- `true` means `-checks all`; turning off the ST rules below matches
            -- the CLI default, so the editor reports what `staticcheck ./...` does.
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
