return {
    "windwp/nvim-ts-autotag",
    event = "InsertEnter",
    ft = { "html", "javascriptreact", "typescriptreact" },
    config = function()
        require("nvim-ts-autotag").setup()
    end,
}
