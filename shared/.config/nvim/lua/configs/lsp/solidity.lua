-- Solidity options
vim.api.nvim_create_autocmd("FileType", {
    pattern = "solidity",
    callback = function(ev)
        vim.bo[ev.buf].tabstop = 4
        vim.bo[ev.buf].shiftwidth = 4
        vim.bo[ev.buf].expandtab = true
    end,
})

-- Solidity LSP (Nomic Foundation — Foundry/Hardhat support)
vim.lsp.config("solidity_ls_nomicfoundation", {
    cmd = { "nomicfoundation-solidity-language-server", "--stdio" },
    filetypes = { "solidity" },
    root_markers = {
        "foundry.toml",
        "hardhat.config.js",
        "hardhat.config.ts",
        "remappings.txt",
        "package.json",
        ".git",
    },
})

-- Solidity LSP (asyncswap/solidity-language-server — Rust-based high performance)
vim.lsp.config("solidity_ls", {
    cmd = { "solidity-language-server", "--stdio" },
    filetypes = { "solidity" },
    root_markers = {
        "foundry.toml",
        "hardhat.config.js",
        "hardhat.config.ts",
        "remappings.txt",
        "package.json",
        ".git",
    },
})

-- TOGGLE LSP HERE: Comment/uncomment the one you want to use:
-- vim.lsp.enable("solidity_ls_nomicfoundation") -- Nomic Foundation (Node-based, currently active)
vim.lsp.enable("solidity_ls") -- asyncswap (Rust-based, cargo install solidity-language-server)


