-- Prisma LSP
--
-- No custom `root_dir` here on purpose. In Neovim 0.11 the function form of
-- `root_dir` is `fun(bufnr, on_dir)` and it must *call* `on_dir(path)`; a
-- function that merely returns a path never activates the server (`:h
-- lsp-root_dir()`). The old config passed the lspconfig 0.10-style
-- `function(fname) return ... end`, so `on_dir` was never called and prismals
-- silently never attached to any schema.prisma.
--
-- `root_markers` does the same job declaratively and is checked in order:
-- schema.prisma first (monorepo: packages/db/prisma/), then the package root.
vim.lsp.config("prismals", {
    root_markers = { "schema.prisma", "package.json", ".git" },
})
vim.lsp.enable("prismals")
