-- Load LSP configurations
return {
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("configs.lspconfig")
        end,
    },
}
