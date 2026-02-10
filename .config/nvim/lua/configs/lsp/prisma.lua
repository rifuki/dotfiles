-- Prisma LSP
vim.lsp.config("prismals", {
    root_dir = function(fname)
        return require("lspconfig.util").root_pattern("schema.prisma")(fname)
    end,
})
vim.lsp.enable("prismals")
