-- PHP LSP (Intelephense)
vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'php', 'phtml' },
    callback = function(ev)
        vim.lsp.start({
            name = 'intelephense',
            cmd = { 'intelephense', '--stdio' },
            root_dir = vim.fs.root(ev.buf, { 'composer.json', '.git' }),
            settings = {
                intelephense = {
                    files = {
                        maxSize = 5000000,
                    },
                    environment = {
                        phpVersion = "8.2",
                    },
                },
            },
        })
    end,
})
