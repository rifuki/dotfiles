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
                "rust_analyzer",
                "taplo",
                "ts_ls",
                "dockerls",
                "yamlls",
                "gh_actions_ls",
                "prismals",
                "jsonls",
                "cssls",
                "html",
                "bashls",
            },
            automatic_installation = true,
        })
    end,
}
