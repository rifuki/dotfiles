return {
    "williamboman/mason.nvim",
    dependencies = {
        "williamboman/mason-lspconfig.nvim",
        "neovim/nvim-lspconfig",
    },
    config = function()
        require("mason").setup({
            ensure_installed = {
                -- Formatters
                "prettierd",
                "stylua",
            },
        })
        require("mason-lspconfig").setup({
            ensure_installed = {
                "lua_ls",
                -- rust_analyzer managed by rustup + rustaceanvim
                "taplo", -- TOML language server
                "ts_ls",
                "denols",
                "intelephense",
                "dockerls",
                "yamlls",
                "gh_actions_ls",
                "prismals",
                "jsonls",
                "cssls",
                "html",
                "bashls",
                "clangd",
                "solidity_ls_nomicfoundation",
                "tailwindcss", -- Tailwind CSS intellisense
            },
            automatic_installation = true,
            automatic_enable = {
                exclude = { "taplo", "move_analyzer" }, -- taplo: manual config, move_analyzer: use sui-move-analyzer from cargo instead
            },
        })
    end,
}
