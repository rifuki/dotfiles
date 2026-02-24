return {
    "stevearc/conform.nvim",
    opts = {
        formatters_by_ft = {
            javascript = { "prettierd" },
            typescript = { "prettierd" },
            javascriptreact = { "prettierd" },
            typescriptreact = { "prettierd" },
            json = { "prettierd" },
            jsonc = { "prettierd" },
            html = { "prettierd" },
            css = { "prettierd" },
            scss = { "prettierd" },
            yaml = { "prettierd" },
            markdown = { "prettierd" },
            lua = { "stylua" },
            solidity = { "forge_fmt" },
        },
        -- Note: prettierd uses .prettierrc config file (CLI args not supported well)
        -- Create .prettierrc in project root for custom settings:
        -- { "printWidth": 100, "proseWrap": "never" }
    },
}
