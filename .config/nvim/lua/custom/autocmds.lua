-- Custom autocmds (load after NvChad autocmds if any)

-- Set commentstring for JSX/TSX files
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "javascriptreact", "typescriptreact", "html" },
    callback = function()
        vim.opt_local.commentstring = "{/* %s */}"
    end,
    desc = "Set JSX/TSX comment style",
})

-- Git commit message formatting (best practices)
vim.api.nvim_create_autocmd("FileType", {
    pattern = "gitcommit",
    callback = function()
        vim.opt_local.wrap = true
        vim.opt_local.spell = true
        vim.opt_local.textwidth = 72
        vim.opt_local.colorcolumn = "51,73"
        vim.opt_local.formatoptions:append("t") -- auto wrap text
    end,
    desc = "Git commit message formatting",
})
