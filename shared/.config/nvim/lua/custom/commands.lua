-- Custom command overrides (load after plugins have registered theirs)

-- nvim-lspconfig's :LspRestart only knows clients registered through
-- vim.lsp.config (see its plugin/lspconfig.lua). rustaceanvim, copilot.vim and
-- crates.nvim start their clients directly with vim.lsp.start, so :LspRestart
-- printed "Invalid server name '<client>'" and restarted nothing.
-- Route those to the command that actually restarts them.
local manual = {
    ["rust-analyzer"] = { cmd = ":RustAnalyzer", run = "RustAnalyzer restart" },
    ["GitHub Copilot"] = { cmd = ":Copilot", run = "Copilot restart" },
    ["crates.nvim"] = { cmd = ":Crates", run = "Crates reload" },
}

local function lsp_restart(info)
    local names = info.fargs
    if #names == 0 then
        names = vim
            .iter(vim.lsp.get_clients())
            :map(function(client)
                return client.name
            end)
            :totable()
    end

    local deferred = {}
    for _, name in ipairs(names) do
        local handler = manual[name]
        if handler then
            if vim.fn.exists(handler.cmd) == 2 then
                vim.cmd(handler.run)
            else
                vim.notify(("%s is not loaded yet"):format(name), vim.log.levels.WARN)
            end
        elseif vim.lsp.config[name] ~= nil then
            vim.lsp.enable(name, false)
            if info.bang then
                vim.iter(vim.lsp.get_clients({ name = name })):each(function(client)
                    client:stop(true)
                end)
            end
            table.insert(deferred, name)
        else
            vim.notify(("No restart path for LSP client '%s'"):format(name), vim.log.levels.WARN)
        end
    end

    if #deferred > 0 then
        vim.defer_fn(function()
            for _, name in ipairs(deferred) do
                vim.lsp.enable(name)
            end
        end, 500)
    end
end

-- lspconfig is lazy-loaded on BufReadPre and defines :LspRestart when its
-- plugin file is sourced, which always happens before a client can attach.
-- Claiming the name on LspAttach therefore lands after it, and unlike
-- User VeryLazy it also fires in --headless (VeryLazy waits on UIEnter).
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function()
        vim.api.nvim_create_user_command("LspRestart", lsp_restart, {
            desc = "Restart LSP clients, including ones not registered via vim.lsp.config",
            nargs = "?",
            bang = true,
            complete = function(arg_lead)
                return vim.tbl_filter(function(name)
                    return name:find(arg_lead, 1, true) ~= nil
                end, vim.iter(vim.lsp.get_clients()):map(function(c)
                    return c.name
                end):totable())
            end,
        })
    end,
    desc = "Override :LspRestart to handle manually-started LSP clients",
})
