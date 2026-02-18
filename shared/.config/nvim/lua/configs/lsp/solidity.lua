-- Solidity LSP (Nomic Foundation — Foundry support)
vim.lsp.config("solidity_ls_nomicfoundation", {
    root_dir = function(fname)
        local util = require("lspconfig.util")
        return util.root_pattern("foundry.toml", "hardhat.config.js", "hardhat.config.ts")(fname)
    end,
    single_file_support = true,
})
vim.lsp.enable("solidity_ls_nomicfoundation")
