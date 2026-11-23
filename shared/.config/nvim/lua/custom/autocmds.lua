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

-- autoread only acts when something runs :checktime, and commands run in the built-in terminal
-- (cargo add, git pull) never do, so a buffer kept showing the old file until :e.
vim.o.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "TermLeave", "TermClose" }, {
    callback = function()
        if vim.fn.getcmdwintype() == "" then
            vim.cmd("silent! checktime")
        end
    end,
    desc = "Reload buffers changed on disk",
})

-- tombi checks `[[bin]] path = ...` only on save, so a file created or moved from NvimTree left a
-- stale "does not exist" error. Re-send didSave when coming back to an unmodified TOML buffer.
vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained" }, {
    pattern = "*.toml",
    callback = function(args)
        if vim.bo[args.buf].modified then
            return
        end
        for _, client in ipairs(vim.lsp.get_clients({ bufnr = args.buf, name = "tombi" })) do
            client:notify("textDocument/didSave", { textDocument = { uri = vim.uri_from_bufnr(args.buf) } })
        end
    end,
    desc = "Re-lint TOML when returning to it",
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
