vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46/"
vim.g.mapleader = " "

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
    local repo = "https://github.com/folke/lazy.nvim.git"
    vim.fn.system({ "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath })
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require("configs.lazy")

-- load plugins
require("lazy").setup({
    {
        "NvChad/NvChad",
        lazy = false,
        branch = "v2.5",
        import = "nvchad.plugins",
    },

    { import = "plugins" },
}, lazy_config)

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require("options")
require("nvchad.autocmds")

vim.schedule(function()
    require("mappings")
end)

--> Below are some custom options and settings <--
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"

vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true

-- Set commentstring for different file types
vim.cmd([[autocmd FileType javascriptreact,typescriptreact,html setlocal commentstring={/*\ %s\ */}]])

-- -- Temporarily disableNoice when writing files
-- vim.api.nvim_create_autocmd("BufWritePost", {
--     callback = function()
--         -- Non-blocking call to disable Noice
--         require("noice").disable()
--
--         -- Re-enable Noice after a short delay
--         vim.defer_fn(function()
--             require("noice").enable()
--         end, 1000) -- Adjust the delay as needed
--     end,
-- })

-- Set up auto formatting for specific file types
vim.api.nvim_create_autocmd("FileType", {
    pattern = "gitcommit",
    callback = function()
        vim.opt_local.wrap = true
        vim.opt_local.spell = true
        vim.opt_local.textwidth = 72
        vim.opt_local.colorcolumn = "51,73"
        vim.opt_local.formatoptions:append("t") -- auto wrap text on typing
    end,
})

-- Set up clipboard for WSL
local is_wsl = vim.fn.has("wsl") == 1
if is_wsl then
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
