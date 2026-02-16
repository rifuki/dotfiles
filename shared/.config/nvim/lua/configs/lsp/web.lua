-- TypeScript/JavaScript LSP (via Mason)
-- Only starts if NOT a Deno project (no deno.json)
vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
    callback = function(ev)
        -- Check if Deno project
        local deno_root = vim.fs.root(ev.buf, { 'deno.json', 'deno.jsonc' })
        if deno_root then
            return -- Skip ts_ls if Deno project
        end

        vim.lsp.start({
            name = 'ts_ls',
            cmd = { 'typescript-language-server', '--stdio' },
            root_dir = vim.fs.root(ev.buf, { 'package.json', 'tsconfig.json', 'jsconfig.json' }),
        })
    end,
})

-- Deno LSP (only for Deno projects with deno.json)
vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
    callback = function(ev)
        local deno_root = vim.fs.root(ev.buf, { 'deno.json', 'deno.jsonc' })
        if not deno_root then
            return -- Only start if Deno project
        end

        vim.lsp.start({
            name = 'denols',
            cmd = { 'deno', 'lsp' },
            root_dir = deno_root,
            init_options = {
                lint = true,
                unstable = true,
                suggest = {
                    imports = {
                        hosts = {
                            ["https://deno.land"] = true,
                            ["https://cdn.nest.land"] = true,
                            ["https://crux.land"] = true,
                        },
                    },
                },
            },
        })
    end,
})

-- HTML LSP (via Mason)
vim.api.nvim_create_autocmd('FileType', {
    pattern = 'html',
    callback = function(ev)
        vim.lsp.start({
            name = 'html',
            cmd = { 'vscode-html-language-server', '--stdio' },
            root_dir = vim.fs.root(ev.buf, { 'package.json', '.git' }),
        })
    end,
})

-- CSS LSP (via Mason)
vim.api.nvim_create_autocmd('FileType', {
    pattern = 'css',
    callback = function(ev)
        vim.lsp.start({
            name = 'cssls',
            cmd = { 'vscode-css-language-server', '--stdio' },
            root_dir = vim.fs.root(ev.buf, { 'package.json', '.git' }),
        })
    end,
})
