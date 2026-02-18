-- Solidity LSP (Nomic Foundation — Foundry/Hardhat support)
vim.api.nvim_create_autocmd("FileType", {
    pattern = "solidity",
    callback = function(ev)
        vim.lsp.start({
            name = "solidity_ls_nomicfoundation",
            cmd = { "nomicfoundation-solidity-language-server", "--stdio" },
            root_dir = vim.fs.root(ev.buf, { "foundry.toml", "hardhat.config.js", "hardhat.config.ts" })
                or vim.fn.fnamemodify(ev.file, ":h"),
        })
    end,
})
