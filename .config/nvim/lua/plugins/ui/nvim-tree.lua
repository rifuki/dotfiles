return {
    "nvim-tree/nvim-tree.lua",
    opts = function(_, opts)
        opts.trash = {
            cmd = "trash",
        }

        opts.on_attach = function(bufnr)
            local api = require("nvim-tree.api")
            api.config.mappings.default_on_attach(bufnr)

            -- Swap: d = trash, D = remove
            vim.keymap.set("n", "d", api.fs.trash, {
                buffer = bufnr,
                desc = "nvim-tree: Trash",
                noremap = true,
                silent = true,
                nowait = true,
            })

            vim.keymap.set("n", "D", api.fs.remove, {
                buffer = bufnr,
                desc = "nvim-tree: Delete (permanent)",
                noremap = true,
                silent = true,
                nowait = true,
            })
        end

        return opts
    end,
}
