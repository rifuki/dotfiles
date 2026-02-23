-- Custom options (NvChad options loaded from init.lua)

-- Add custom parser path for Move (before plugin loads)
vim.opt.runtimepath:prepend(vim.fn.stdpath("data") .. "/site/parser")

local o = vim.opt

-- Fold settings (for Treesitter)
o.foldmethod = "expr"
o.foldexpr = "nvim_treesitter#foldexpr()"
o.foldlevel = 99
o.foldlevelstart = 99
o.foldenable = true

-- Move language filetype detection (must be early, before lspconfig lazy loads)
vim.filetype.add({
    extension = { move = "move" },
    pattern = { [".*%.move"] = "move" },
})
-- Register Move treesitter parser (manually installed from MystenLabs/sui)
-- Parser: ~/.local/share/nvim/lazy/nvim-treesitter/parser/move.so
-- Queries: ~/.config/nvim/queries/move/highlights.scm
vim.treesitter.language.register("move", "move")

-- WSL clipboard
if vim.fn.has("wsl") == 1 then
    vim.g.clipboard = {
        name = "win32yank-wsl",
        copy = {
            ["+"] = "win32yank.exe -i --crlf",
            ["*"] = "win32yank.exe -i --crlf",
        },
        paste = {
            ["+"] = "win32yank.exe -o --lf",
            ["*"] = "win32yank.exe -o --lf",
        },
        cache_enabled = 0,
    }
end
