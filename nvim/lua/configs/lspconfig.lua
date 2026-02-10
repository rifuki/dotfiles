require("nvchad.configs.lspconfig").defaults()

-- ========== Default Servers ==========
vim.lsp.enable({ "lua_ls", "taplo", "dockerls", "bashls" })

-- ========== GitHub Actions LSP ==========
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = { ".github/workflows/*.yml", ".github/workflows/*.yaml" },
    callback = function()
        vim.bo.filetype = "yaml.github-actions"
    end,
})

vim.lsp.config("gh_actions_ls", {
    filetypes = { "yaml.github-actions" },
    settings = {
        diagnostics = {
            enable = true,
        },
    },
    root_dir = function(fname)
        local util = require("lspconfig.util")
        return util.root_pattern(".github/workflows")(fname) or util.find_git_ancestor(fname)
    end,
})
vim.lsp.enable("gh_actions_ls")

-- ========== YAML LSP ==========
vim.lsp.config("yamlls", {
    settings = {
        yaml = {
            schemas = {
                ["https://json.schemastore.org/docker-compose.json"] = "docker-compose*.yml",
            },
            validate = true,
            completion = true,
            hover = true,
        },
    },
})
vim.lsp.enable("yamlls")

-- ========== Deno LSP ==========
vim.lsp.config("denols", {
    root_dir = function(fname)
        return require("lspconfig.util").root_pattern("deno.json", "deno.jsonc")(fname)
    end,
    single_file_support = false,
})
vim.lsp.enable("denols")

-- ========== Prisma LSP ==========
vim.lsp.config("prismals", {
    root_dir = function(fname)
        return require("lspconfig.util").root_pattern("schema.prisma")(fname)
    end,
})
vim.lsp.enable("prismals")

-- ========== TypeScript/JavaScript LSP ==========
vim.lsp.config("ts_ls", {
    on_attach = function(client, bufnr)
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
        require("nvchad.configs.lspconfig").on_attach(client, bufnr)
    end,
    root_dir = function(fname)
        return require("lspconfig.util").root_pattern("package.json", "tsconfig.json", "jsconfig.json")(fname)
    end,
    single_file_support = false,
})
vim.lsp.enable("ts_ls")

-- ========== HTML LSP (via bun) ==========
vim.lsp.config("html", {
    cmd = { vim.fn.expand("~/.bun/bin/vscode-html-language-server"), "--stdio" },
    filetypes = { "html", "typescriptreact", "javascriptreact" },
})
vim.lsp.enable("html")

-- ========== CSS LSP (via bun) ==========
vim.lsp.config("cssls", {
    cmd = { vim.fn.expand("~/.bun/bin/vscode-css-language-server"), "--stdio" },
    filetypes = { "css", "typescriptreact", "javascriptreact" },
})
vim.lsp.enable("cssls")
