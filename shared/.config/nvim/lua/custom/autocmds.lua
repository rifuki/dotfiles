-- Custom autocmds (load after NvChad autocmds if any)

-- Treat openclaw.json as json5 (openclaw uses json5 parser internally)
vim.filetype.add({
    pattern = {
        [".*/%.openclaw/.*%.json"] = "json5",
    },
})


-- Set commentstring for JSX/TSX files
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "javascriptreact", "typescriptreact", "html" },
    callback = function()
        vim.opt_local.commentstring = "{/* %s */}"
    end,
    desc = "Set JSX/TSX comment style",
})

-- Auto-save Rust files on idle so rust-analyzer checkOnSave runs without manual :w
vim.api.nvim_create_autocmd("CursorHold", {
    pattern = "*.rs",
    callback = function()
        if vim.bo.modified and vim.bo.buftype == "" then
            vim.cmd("silent! write")
        end
    end,
    desc = "Auto-save Rust files for live LSP diagnostics",
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
