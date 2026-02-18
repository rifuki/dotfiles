return {
    "williamboman/mason.nvim",
    dependencies = {
        "williamboman/mason-lspconfig.nvim",
        "neovim/nvim-lspconfig",
    },
    config = function()
        require("mason").setup()
        require("mason-lspconfig").setup({
            ensure_installed = {
                "lua_ls",
                -- rust_analyzer managed by rustup + rustaceanvim
                "taplo",
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
                "solidity_ls_nomicfoundation",
            },
            automatic_installation = true,
        })
    end,
}
