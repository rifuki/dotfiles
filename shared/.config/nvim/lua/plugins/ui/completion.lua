return {
    -- Disable NvChad's cmp-async-path (Codeberg blocks Tencent Cloud IPs;
    -- cmp-path below covers the same use case)
    { "https://codeberg.org/FelipeLema/cmp-async-path.git", enabled = false },

    -- nvim-cmp completion engine
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-path",
        },
        opts = function(_, opts)
            local cmp = require("cmp")

            local function hide_solidity_spdx_snippet(entry, ctx)
                if vim.bo[ctx.bufnr].filetype ~= "solidity" then
                    return true
                end

                local label = entry.completion_item.label or ""
                local word = entry:get_word() or ""
                if label ~= "spdx" and word ~= "spdx" then
                    return true
                end

                local row = ctx.cursor.row
                local col = ctx.cursor.col
                local line = vim.api.nvim_buf_get_lines(ctx.bufnr, row - 1, row, true)[1] or ""
                local before_cursor = line:sub(1, col - 1)

                -- Keep the snippet for `spdx` at the beginning of a directive line,
                -- but let the LSP own `// spdx` so it can replace the whole line
                -- without producing `// // SPDX-License-Identifier: ...`.
                return not before_cursor:match("//%s*[%w_%-]*$")
            end

            opts.sources = cmp.config.sources({
                { name = "nvim_lsp", priority = 1000 },
            }, {
                { name = "luasnip", priority = 750, entry_filter = hide_solidity_spdx_snippet },
                { name = "buffer", priority = 500 },
                { name = "nvim_lua", priority = 500 },
                { name = "path", priority = 250 },
            })

            return opts
        end,
    },

    -- Command line completion
    {
        "hrsh7th/cmp-cmdline",
        lazy = false,
        dependencies = {
            "hrsh7th/nvim-cmp",
            "hrsh7th/cmp-path",
        },
        config = function()
            local cmp = require("cmp")

            -- Search completion (/)
            cmp.setup.cmdline("/", {
                mapping = cmp.mapping.preset.cmdline(),
                sources = {
                    { name = "buffer" },
                },
            })

            -- Command completion (:)
            cmp.setup.cmdline(":", {
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources({
                    { name = "path" },
                }, {
                    {
                        name = "cmdline",
                        option = {
                            ignore_cmds = { "Man", "!" },
                        },
                    },
                }),
            })
        end,
    },
}
