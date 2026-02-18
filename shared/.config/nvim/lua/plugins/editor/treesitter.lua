return {
    "nvim-treesitter/nvim-treesitter",
    opts = {
        ensure_installed = {
            "vim",
            "lua",
            "vimdoc",
            "bash",
            "json",
            "gitignore",
            "toml",
            "yaml",
            "nginx",
            "sql",
            "html",
            "css",
            "javascript",
            "typescript",
            "tsx",
            "rust",
            "markdown",
            "markdown_inline",
            "caddy",
            "solidity",
        },
        highlight = {
            enable = true,
            disable = { "move" }, -- no tree-sitter parser; using custom vim syntax via move-lang.lua
        },
        indent = {
            enable = true,
        },
    },
}
