return {
    -- Manual LSP setup untuk sui-move-analyzer
    -- {
    --     "neovim/nvim-lspconfig",
    --     config = function()
    --         local lspconfig = require("lspconfig")
    --         local configs = require("lspconfig.configs")
    --
    --         -- Setup custom LSP untuk sui-move-analyzer
    --         if not configs.sui_move_analyzer then
    --             configs.sui_move_analyzer = {
    --                 default_config = {
    --                     cmd = { "sui-move-analyzer" },
    --                     filetypes = { "move" },
    --                     root_dir = function(fname)
    --                         -- Cari Move.toml dulu (untuk Sui projects)
    --                         local move_toml = lspconfig.util.root_pattern("Move.toml")(fname)
    --                         if move_toml then
    --                             return move_toml
    --                         end
    --                         -- Fallback ke git root
    --                         return lspconfig.util.find_git_ancestor(fname)
    --                     end,
    --                     settings = {
    --                         ["sui-move-analyzer"] = {
    --                             ["enable-all-features"] = true,
    --                             ["external-packages"] = true,
    --                         },
    --                     },
    --                     capabilities = require("cmp_nvim_lsp").default_capabilities(),
    --                 },
    --             }
    --         end
    --
    --         -- Start the LSP
    --         lspconfig.sui_move_analyzer.setup({
    --             on_attach = function(client, bufnr)
    --                 print("Sui move analyzer attached to buffer: " .. bufnr)
    --                 print("Root dir: " .. (client.config.root_dir or "none"))
    --
    --                 -- Key mappings untuk LSP
    --                 local opts = { noremap=true, silent=true, buffer=bufnr }
    --                 vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    --                 vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    --                 vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
    --                 vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
    --                 vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
    --             end,
    --         })
    --     end,
    -- },

    -- File type detection dan syntax highlighting
    {
        "nvim-treesitter/nvim-treesitter",
        config = function()
            -- Configure diagnostics untuk better error display
            vim.diagnostic.config({
                virtual_text = {
                    prefix = "●", -- Could be '■', '▎', 'x'
                },
                signs = true,
                underline = true,
                update_in_insert = false,
                severity_sort = false,
                float = {
                    border = "rounded",
                    source = "always",
                    header = "",
                    prefix = "",
                },
            })

            -- Define diagnostic signs
            local signs = { Error = "󰅚 ", Warn = "󰀪 ", Hint = "󰌶 ", Info = " " }
            for type, icon in pairs(signs) do
                local hl = "DiagnosticSign" .. type
                vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
            end

            -- Filetype detection
            vim.filetype.add({
                extension = {
                    move = "move",
                },
                pattern = {
                    [".*%.move"] = "move",
                },
            })

            -- Enhanced syntax highlighting
            vim.api.nvim_create_autocmd("FileType", {
                pattern = "move",
                callback = function()
                    local buf = vim.api.nvim_get_current_buf()

                    -- Set buffer options
                    vim.bo[buf].commentstring = "// %s"
                    vim.bo[buf].tabstop = 4
                    vim.bo[buf].shiftwidth = 4
                    vim.bo[buf].expandtab = true

                    -- Enhanced syntax highlighting
                    vim.cmd([[
                        " Move language syntax highlighting
                        syntax clear
                        
                        " Keywords
                        syntax keyword moveKeyword module use fun struct has store key drop copy phantom public native friend acquires script const let mut return abort break continue if else while loop for as move
                        syntax keyword moveKeyword entry public(friend) public(package) 
                        
                        " Sui-specific keywords
                        syntax keyword moveKeyword object uid transfer freeze share delete
                        syntax keyword moveSuiKeyword sui clock tx_context TxContext
                        
                        " Types
                        syntax keyword moveType address signer u8 u16 u32 u64 u128 u256 bool vector String
                        syntax keyword moveSuiType ID UID Object Coin Balance Supply
                        
                        " Built-in functions
                        syntax keyword moveBuiltin assert vector borrow borrow_mut move_to move_from exists
                        
                        " Booleans
                        syntax keyword moveBoolean true false
                        
                        " Numbers
                        syntax match moveNumber '\v<\d+>'
                        syntax match moveHex '\v0x[0-9a-fA-F]+'
                        
                        " Addresses
                        syntax match moveAddress '\v0x[0-9a-fA-F]{1,40}'
                        
                        " Strings
                        syntax region moveString start='"' end='"' contains=moveStringEscape
                        syntax match moveStringEscape '\v\\.' contained
                        
                        " Comments
                        syntax region moveComment start='//' end='$' contains=moveTodo
                        syntax region moveBlockComment start='/\*' end='\*/' contains=moveTodo
                        syntax keyword moveTodo TODO FIXME NOTE XXX contained
                        
                        " Attributes
                        syntax match moveAttribute '\v#\[.*\]'
                        
                        " Module paths (untuk sui::)
                        syntax match moveModulePath '\v[a-zA-Z_][a-zA-Z0-9_]*::[a-zA-Z_][a-zA-Z0-9_]*'
                        
                        " Generics
                        syntax region moveGeneric start='<' end='>' contained contains=moveType,moveModulePath
                        
                        " Function calls
                        syntax match moveFunctionCall '\v[a-zA-Z_][a-zA-Z0-9_]*\ze\s*\('
                        
                        " Highlighting
                        highlight link moveKeyword Keyword
                        highlight link moveSuiKeyword Special
                        highlight link moveType Type
                        highlight link moveSuiType Type
                        highlight link moveBuiltin Function
                        highlight link moveBoolean Boolean
                        highlight link moveNumber Number
                        highlight link moveHex Number
                        highlight link moveAddress Number
                        highlight link moveString String
                        highlight link moveStringEscape SpecialChar
                        highlight link moveComment Comment
                        highlight link moveBlockComment Comment
                        highlight link moveTodo Todo
                        highlight link moveAttribute PreProc
                        highlight link moveModulePath Include
                        highlight link moveFunctionCall Function
                    ]])
                end,
            })
        end,
    },

    -- Optional: Mason auto-install move-analyzer
    -- {
    --     "williamboman/mason.nvim",
    --     opts = {
    --         ensure_installed = {
    --             "move-analyzer",
    --         },
    --     },
    -- },

    -- Optional: Better completion
    {
        "hrsh7th/nvim-cmp",
        opts = function(_, opts)
            opts.sources = opts.sources or {}
            table.insert(opts.sources, { name = "nvim_lsp" })
        end,
    },
}
