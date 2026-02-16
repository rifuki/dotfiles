-- GitHub Actions LSP
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

-- YAML LSP
vim.lsp.config("yamlls", {
    settings = {
        yaml = {
            schemas = {
                ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "docker-compose*.yml",
            },
            validate = true,
            completion = true,
            hover = true,
        },
    },
})
vim.lsp.enable("yamlls")
