-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

local lspconfig = require("lspconfig")

local servers = { "lua_ls", "taplo", "dockerls", "bashls" }
local nvlsp = require("nvchad.configs.lspconfig")

-- lsps with default config
for _, lsp in ipairs(servers) do
    lspconfig[lsp].setup({
        on_attach = nvlsp.on_attach,
        on_init = nvlsp.on_init,
        capabilities = nvlsp.capabilities,
    })
end

-- Autocmd: Set filetype yaml.github-actions untuk workflow
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = { ".github/workflows/*.yml", ".github/workflows/*.yaml" },
    callback = function()
        vim.bo.filetype = "yaml.github-actions"
    end,
})

-- LSP for workflow GitHub Actions
lspconfig.gh_actions_ls.setup({
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
    filetypes = { "yaml.github-actions" },
    settings = {
        diagnostics = {
            enable = true,
        },
    },
    root_dir = function(fname)
        return lspconfig.util.root_pattern(".github/workflows")(fname) or lspconfig.util.find_git_ancestor(fname)
    end,
})

-- YAML LSP
lspconfig.yamlls.setup({
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
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

-- Deno LSP
-- lspconfig.denols.setup({
--     on_attach = nvlsp.on_attach,
--     on_init = nvlsp.on_init,
--     capabilities = nvlsp.capabilities,
--     root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc"),
--     single_file_support = false,
-- })

-- Prisma LSP
lspconfig.prismals.setup({
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
    root_dir = lspconfig.util.root_pattern("schema.prisma"),
})

-- TypeScript/JavaScript
lspconfig.ts_ls.setup({
    on_attach = function(client, bufnr)
        -- Disable formatting for ts_ls to avoid handle TSX
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
        nvlsp.on_attach(client, bufnr)
    end,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
    root_dir = lspconfig.util.root_pattern("package.json", "tsconfig.json", "jsconfig.json"),
    single_file_support = false,
})

-- HTML/TSX (vscode-html-language-server via bun)
lspconfig.html.setup({
    cmd = { vim.fn.expand("~/.bun/bin/vscode-html-language-server"), "--stdio" },
    filetypes = { "html", "typescriptreact", "javascriptreact" },
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
})

-- CSS/TSX (vscode-css-language-server via bun)
lspconfig.cssls.setup({
    cmd = { vim.fn.expand("~/.bun/bin/vscode-css-language-server"), "--stdio" },
    filetypes = { "css", "typescriptreact", "javascriptreact" },
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
})

-- lspconfig.intelephense.setup({
--     on_attach = nvlsp.on_attach,
--     on_init = nvlsp.on_init,
--     capabilities = nvlsp.capabilities,
--     settings = {
--         filetypes = { "php", "phtml" },
--         memoryLimit = 4096,
--         configuration = {
--             phpVersion = "8.2",
--         },
--     },
-- })

-- Autocmd: Set filetype move untuk Sui Move files
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = "*.move",
    callback = function()
        vim.bo.filetype = "move"
        vim.bo.commentstring = "// %s"
        vim.bo.tabstop = 4
        vim.bo.shiftwidth = 4
        vim.bo.expandtab = true
    end,
})

-- Sui Move Analyzer LSP (MoveBit)
-- git clone https://github.com/movebit/sui-move-analyzer.git
-- cd sui-move-analyzer
-- cargo install --path .
local configs = require("lspconfig.configs")
if not configs.move_analyzer then
    configs.move_analyzer = {
        default_config = {
            cmd = { "sui-move-analyzer" },
            filetypes = { "move" },
            root_dir = function(fname)
                -- Priority Move.toml (untuk Sui projects)
                local move_toml = lspconfig.util.root_pattern("Move.toml")(fname)
                if move_toml then
                    return move_toml
                end
                -- Fallback to git root
                return lspconfig.util.find_git_ancestor(fname)
            end,
            settings = {
                ["sui-move-analyzer"] = {
                    ["enable-all-features"] = true,
                    ["external-packages"] = true,
                },
            },
        },
    }
end

-- Sui Move Analyzer LSP
lspconfig.move_analyzer.setup({
    on_attach = function(client, bufnr)
        print("Sui move analyzer attached to buffer: " .. bufnr)
        print("Root dir: " .. (client.config.root_dir or "none"))

        -- Call default nvlsp on_attach first
        nvlsp.on_attach(client, bufnr)

        -- Additional key mappings for LSP
        local opts = { noremap = true, silent = true, buffer = bufnr }
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
    end,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
})
