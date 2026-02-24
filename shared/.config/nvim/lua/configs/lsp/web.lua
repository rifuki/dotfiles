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

-- Tailwind CSS LSP
-- Simple root detection: works for both v3 (tailwind.config.*) and v4 (package.json)
-- Safe to use since it only activates for CSS/HTML/JSX/TSX/Vue/Svelte files anyway
vim.lsp.config("tailwindcss", {
    filetypes = {
        "css", "scss", "sass",
        "html", "htmldjango",
        "javascript", "typescript",
        "javascriptreact", "typescriptreact",
        "vue", "svelte",
    },
    root_markers = {
        "tailwind.config.js",
        "tailwind.config.ts",
        "tailwind.config.mjs",
        "tailwind.config.cjs",
        "package.json",  -- Fallback for v4 projects
    },
    settings = {
        tailwindCSS = {
            classAttributes = { "class", "className", "classList", "ngClass" },
            includeLanguages = {
                typescript = "javascript",
                typescriptreact = "javascript",
            },
            lint = {
                cssConflict = "warning",
                invalidApply = "error",
                invalidConfigPath = "error",
                invalidScreen = "error",
                invalidTailwindDirective = "error",
                invalidVariant = "error",
                recommendedVariantOrder = "warning",
            },
            validate = true,
            colorDecorators = true,
        },
    },
})
vim.lsp.enable("tailwindcss")
