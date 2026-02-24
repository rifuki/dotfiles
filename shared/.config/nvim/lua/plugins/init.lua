-- Load LSP configurations
return {
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("configs.lspconfig")
        end,
    },
    {
        "vuki656/package-info.nvim",
        event = { "BufRead package.json" },
        dependencies = { "MunifTanjim/nui.nvim" },
        config = function()
            require("package-info").setup({
                autostart = true,
                hide_up_to_date = false,
                package_manager = "npm",
                icons = {
                    enable = true,
                    style = {
                        up_to_date = "| ",
                        outdated = "| ",
                        invalid = "| ",
                    },
                },
                -- Use default highlight groups (no custom colors)
                -- The plugin will use its internal defaults
            })

            -- Override highlight colors after setup
            vim.cmd([[
                highlight PackageInfoUpToDate guifg=#3C4048
                highlight PackageInfoOutdated guifg=#FCA5A5
                highlight PackageInfoInvalid guifg=#EE4B2B
            ]])

            -- Keymaps
            local map = vim.keymap.set
            local pi = require("package-info")

            map("n", "<leader>ns", pi.show, { desc = "Show package versions", silent = true })
            map("n", "<leader>nc", pi.hide, { desc = "Hide package versions", silent = true })
            map("n", "<leader>nu", pi.update, { desc = "Update package on line", silent = true })
            map("n", "<leader>nU", pi.change_version, { desc = "Change package version", silent = true })
        end,
    },
}
