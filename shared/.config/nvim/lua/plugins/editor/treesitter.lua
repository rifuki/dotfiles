return {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
        "windwp/nvim-ts-autotag",
    },
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
        auto_install = true,
        highlight = {
            enable = true,
        },
        indent = {
            enable = true,
        },
    },
}
