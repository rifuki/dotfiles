-- Sui Move syntax + LSP
-- Note: filetype detection is in custom/options.lua (early load)

-- git clone https://github.com/movebit/sui-move-analyzer.git
-- cd sui-move-analyzer
-- cargo install --path .
--
-- Fix sui-move-analyzer partial clone caches.
-- Problem: sui-move-analyzer creates tree:0 partial clones (no working files),
-- causing get_package_compile_diagnostics to fail → no inline diagnostics.
-- Solution: copy packages from the hash-based cache populated by `sui move build`.
local function fix_sui_analyzer_cache()
    local move_cache = vim.fn.expand("~/.move")
    local packages = "crates/sui-framework/packages"

    -- Find a populated hash cache (created by `sui move build`)
    local src = nil
    for _, dir in ipairs(vim.fn.glob(move_cache .. "/git/https___*", false, true)) do
        if vim.fn.filereadable(dir .. "/" .. packages .. "/sui-framework/Move.toml") == 1 then
            src = dir
            break
        end
    end
    if not src then return end -- sui move build hasn't run yet, nothing to copy from

    -- Fix every framework rev cache that is missing its files
    local prefix = move_cache .. "/https___github_com_MystenLabs_sui_git_framework__"
    for _, dir in ipairs(vim.fn.glob(prefix .. "*", false, true)) do
        if vim.fn.filereadable(dir .. "/" .. packages .. "/sui-framework/Move.toml") == 1 then
            -- Already populated
        else
            -- Remove partial clone flags so future git operations work normally
            if vim.fn.isdirectory(dir .. "/.git") == 1 then
                vim.fn.system({ "git", "-C", dir, "config", "--unset", "remote.origin.partialclonefilter" })
                vim.fn.system({ "git", "-C", dir, "config", "--unset", "remote.origin.promisor" })
            end
            vim.fn.mkdir(dir .. "/" .. packages, "p")
            vim.fn.system({ "cp", "-r", src .. "/" .. packages .. "/sui-framework", dir .. "/" .. packages .. "/" })
            vim.fn.system({ "cp", "-r", src .. "/" .. packages .. "/move-stdlib", dir .. "/" .. packages .. "/" })
        end
    end
end

-- Sui Move Analyzer LSP config (custom server)
local configs = require("lspconfig.configs")
if not configs.move_analyzer then
    configs.move_analyzer = {
        default_config = {
            cmd = { "sui-move-analyzer" },
            filetypes = { "move" },
            root_dir = function(fname)
                local util = require("lspconfig.util")
                return util.root_pattern("Move.toml")(fname)
                    or util.find_git_ancestor(fname)
            end,
            settings = {
                ["sui-move-analyzer"] = {
                    ["enable-all-features"] = true,
                    ["external-packages"] = true,
                },
            },
        },
    }
end

local nvchad_lsp = require("nvchad.configs.lspconfig")
require("lspconfig").move_analyzer.setup({
    on_attach = function(client, bufnr)
        nvchad_lsp.on_attach(client, bufnr)
        fix_sui_analyzer_cache()
    end,
    on_init = nvchad_lsp.on_init,
    capabilities = nvchad_lsp.capabilities,
})

-- Manual command: :SuiFixLsp
vim.api.nvim_create_user_command("SuiFixLsp", fix_sui_analyzer_cache, { desc = "Fix sui-move-analyzer partial clone caches" })

-- Buffer options (treesitter handles syntax highlighting)
vim.api.nvim_create_autocmd("FileType", {
    pattern = "move",
    callback = function()
        local buf = vim.api.nvim_get_current_buf()
        vim.bo[buf].commentstring = "// %s"
        vim.bo[buf].tabstop = 4
        vim.bo[buf].shiftwidth = 4
        vim.bo[buf].expandtab = true
    end,
})
