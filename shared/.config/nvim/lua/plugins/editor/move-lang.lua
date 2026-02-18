-- Move language filetype detection
-- Syntax is handled via after/syntax/move.vim
-- Options are handled via after/ftplugin/move.vim
return {
    "nvim-treesitter/nvim-treesitter",
    init = function()
        vim.filetype.add({
            extension = { move = "move" },
        })
    end,
}
