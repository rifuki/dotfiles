-- Go LSP (gopls, via Mason)
--
-- Mason builds gopls with `go install`, so it is only added to ensure_installed
-- when a Go toolchain is on PATH (see plugins/lsp/mason.lua). Root detection,
-- filetypes and the GOROOT/GOMODCACHE workspace reuse all come from
-- nvim-lspconfig's lsp/gopls.lua; only settings are layered on top here.
vim.lsp.config("gopls", {
    settings = {
        gopls = {
            staticcheck = true,
            usePlaceholders = true,
            analyses = {
                unusedparams = true,
                unusedwrite = true,
                nilness = true,
            },
        },
    },
})
vim.lsp.enable("gopls")
