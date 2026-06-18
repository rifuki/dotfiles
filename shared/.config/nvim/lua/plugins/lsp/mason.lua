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
                "solidity_ls_nomicfoundation@0.8.21",
                "tailwindcss",           -- Tailwind CSS intellisense
            })
        end

        require("mason-lspconfig").setup({
            ensure_installed = lsps,
            automatic_installation = true,
            automatic_enable = {
                exclude = {
                    "taplo", -- manual config
                    "move_analyzer", -- use sui-move-analyzer from cargo instead
                    "solidity_ls_nomicfoundation", -- Solidity LSP is toggled manually in configs/lsp/solidity.lua
                },
            },
        })
    end,
}
