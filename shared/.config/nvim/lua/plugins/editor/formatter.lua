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
            -- prisma has no standalone CLI formatter; prismals implements
            -- textDocument/formatting, so route the filetype through the LSP.
            prisma = { lsp_format = "prefer" },
        },
        -- Note: prettierd uses .prettierrc config file (CLI args not supported well)
        -- Create .prettierrc in project root for custom settings:
        -- { "printWidth": 100, "proseWrap": "never" }
    },
}
