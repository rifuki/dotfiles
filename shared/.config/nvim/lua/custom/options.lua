-- Custom options (NvChad options loaded from init.lua)

-- Add custom parser path for Move (before plugin loads)
vim.opt.runtimepath:prepend(vim.fn.stdpath("data") .. "/site/parser")

local o = vim.opt

-- Faster CursorHold (used for auto-save → live LSP diagnostics on Rust files)
o.updatetime = 500

-- Show LSP diagnostics live while typing in insert mode
vim.diagnostic.config({ update_in_insert = true })

-- Disable swap/backup, use undofile instead (persistent undo, no annoying warnings)
o.swapfile = false
o.backup = false
o.undofile = true

-- Fold settings (for Treesitter)
-- Use Neovim's built-in treesitter foldexpr rather than nvim-treesitter's
-- `nvim_treesitter#foldexpr()`. The vimscript one still exists on the `master`
-- branch this config pins, but it goes through the vimscript bridge once per line
-- on every redraw: measured at 235ms per fold recompute on a 1882-line TypeScript
-- file, against 1.3ms for the native one below.
o.foldmethod = "expr"
o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
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

-- Clipboard. Over SSH, yanks reach the local terminal's clipboard through OSC 52; pasting is
-- the terminal's own (Cmd+V), so the clipboard is never read back. On WSL itself, Windows'.
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
    local osc52 = require("vim.ui.clipboard.osc52")
    local function from_register()
        return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
    end
    vim.g.clipboard = {
        name = "OSC 52",
        copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
        paste = { ["+"] = from_register, ["*"] = from_register },
    }
elseif vim.fn.has("wsl") == 1 then
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
