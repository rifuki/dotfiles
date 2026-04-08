vim.lsp.config("clangd", {
    cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--header-insertion=iwyu",
        "--completion-style=detailed",
        "--fallback-style=llvm",
    },
    filetypes = { "c", "cpp", "objc", "objcpp" },
})
vim.lsp.enable("clangd")
