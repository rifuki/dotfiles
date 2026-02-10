return {
    "nvim-tree/nvim-tree.lua",
    opts = function(_, opts)
        -- Set trash command
        opts.trash = {
            cmd = "trash",
        }
        
        -- Swap d and D: d=trash, D=remove
        opts.on_attach = function(bufnr)
            local api = require("nvim-tree.api")
            
            -- Load default mappings first
            api.config.mappings.default_on_attach(bufnr)
            
            -- Swap: d = trash (was D), D = remove (was d)
            vim.keymap.set('n', 'd', api.fs.trash, { 
                buffer = bufnr, 
                desc = 'nvim-tree: Trash',
                noremap = true,
                silent = true,
                nowait = true,
            })
            
            vim.keymap.set('n', 'D', api.fs.remove, { 
                buffer = bufnr, 
                desc = 'nvim-tree: Delete (permanent)',
                noremap = true,
                silent = true,
                nowait = true,
            })
        end
        
        return opts
    end,
}
