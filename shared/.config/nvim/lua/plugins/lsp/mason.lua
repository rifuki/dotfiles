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

        -- Headless mode: register event listeners BEFORE mason-lspconfig.setup() is called
        -- so we catch every package:install:* event and wait for all installs to finish.
        if #vim.api.nvim_list_uis() == 0 then
            local registry = require("mason-registry")
            local pending = 0

            local function log(msg)
                vim.api.nvim_out_write(msg .. "\n")
            end

            local function on_done()
                pending = pending - 1
                if pending == 0 then
                    log("[mason] all done")
                    vim.schedule(function() vim.cmd("qa!") end)
                end
            end

            registry:on("package:install:start", function(pkg)
                pending = pending + 1
                log("  [mason] → " .. pkg.name)
            end)
            registry:on("package:install:success", function(pkg)
                log("  [mason] ✓ " .. pkg.name)
                on_done()
            end)
            registry:on("package:install:failed", function(pkg)
                log("  [mason] ✗ FAILED: " .. pkg.name)
                on_done()
            end)

            -- Install formatters explicitly (mason-lspconfig only handles LSPs)
            registry.refresh(function()
                for _, name in ipairs({ "prettierd", "stylua" }) do
                    local f_ok, pkg = pcall(registry.get_package, name)
                    if f_ok and not pkg:is_installed() then
                        pkg:install()
                    end
                end
            end)

            -- Fallback: if no installs started after 3s, nothing to install
            vim.defer_fn(function()
                if pending == 0 then
                    log("[mason] nothing to install")
                    vim.cmd("qa!")
                end
            end, 3000)
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
