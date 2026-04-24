return {
    "williamboman/mason.nvim",
    lazy = false,
    dependencies = {
        "williamboman/mason-lspconfig.nvim",
        "neovim/nvim-lspconfig",
    },
    config = function()
        local ok, profile = pcall(require, "utils.profile")
        local is_minimal = ok and profile.is_minimal or false

        require("mason").setup()

        local lsps = {
            "lua_ls",
            -- rust_analyzer managed by rustup + rustaceanvim
            "taplo", -- TOML language server
            "ts_ls",
            "denols",
            "intelephense",
            "dockerls",
            "yamlls",
            "gh_actions_ls",
            "jsonls",
            "cssls",
            "html",
            "bashls",
            "clangd",
        }

        if not is_minimal then
            vim.list_extend(lsps, {
                "prismals",              -- Prisma ORM
                "solidity_ls_nomicfoundation",
                "tailwindcss",           -- Tailwind CSS intellisense
            })
        end

        -- Headless mode: mason-lspconfig skips ensure_installed when no buffers are open.
        -- Explicitly install all packages using the lspconfig→mason package name mapping.
        if #vim.api.nvim_list_uis() == 0 then
            local registry = require("mason-registry")
            local pending = 0

            local function log(msg) vim.api.nvim_out_write(msg .. "\n") end

            local function on_done()
                pending = pending - 1
                if pending == 0 then
                    log("[mason] all done")
                    vim.schedule(function() vim.cmd("qa!") end)
                end
            end

            registry:on("package:install:start",   function(pkg) pending = pending + 1; log("  [mason] → " .. pkg.name) end)
            registry:on("package:install:success",  function(pkg) log("  [mason] ✓ " .. pkg.name); on_done() end)
            registry:on("package:install:failed",   function(pkg) log("  [mason] ✗ " .. pkg.name); on_done() end)

            -- Resolve lspconfig server names → mason package names
            local ok_m, mappings = pcall(require, "mason-lspconfig.mappings.server")
            local to_pkg = (ok_m and mappings.lspconfig_to_package) or {}

            -- Packages to install: LSPs + formatters
            local all = vim.list_extend(vim.deepcopy(lsps), { "prettierd", "stylua" })

            registry.refresh(function()
                for _, name in ipairs(all) do
                    local mason_name = to_pkg[name] or name
                    local f_ok, pkg = pcall(registry.get_package, mason_name)
                    if f_ok and not pkg:is_installed() then
                        pkg:install()
                    end
                end
                -- Fallback: if nothing queued after refresh, nothing to install
                vim.defer_fn(function()
                    if pending == 0 then
                        log("[mason] nothing to install")
                        vim.cmd("qa!")
                    end
                end, 1000)
            end)
        end

        require("mason-lspconfig").setup({
            ensure_installed = lsps,
            automatic_installation = true,
            automatic_enable = {
                exclude = { "taplo", "move_analyzer" }, -- taplo: manual config, move_analyzer: use sui-move-analyzer from cargo instead
            },
        })
    end,
}
