-- Move language support
-- Auto-compiles the tree-sitter parser on first startup if not present.
-- Parser source: MystenLabs/sui (sparse checkout, no full clone needed)
-- Script: scripts/install-move-parser.sh
return {
    dir = vim.fn.stdpath("config"),
    name = "move-lang",
    enabled = not require("utils.profile").is_minimal,
    lazy = false,
    config = function()
        local parser_so = vim.fn.stdpath("data") .. "/site/parser/move.so"
        local script = vim.fn.stdpath("config") .. "/scripts/install-move-parser.sh"

        if vim.fn.filereadable(parser_so) == 0 then
            vim.notify("[move] Installing tree-sitter parser...", vim.log.levels.INFO)
            vim.fn.jobstart({ "bash", script }, {
                on_exit = function(_, code)
                    vim.schedule(function()
                        if code == 0 then
                            vim.notify("[move] Parser installed! Restart nvim.", vim.log.levels.INFO)
                        else
                            vim.notify("[move] Parser install failed. Run :MoveParserInstall manually.", vim.log.levels.WARN)
                        end
                    end)
                end,
            })
        end

        vim.api.nvim_create_user_command("MoveParserInstall", function()
            vim.notify("[move] Reinstalling tree-sitter parser...", vim.log.levels.INFO)
            vim.fn.jobstart({ "bash", script }, {
                on_exit = function(_, code)
                    vim.schedule(function()
                        if code == 0 then
                            vim.notify("[move] Done! Restart nvim.", vim.log.levels.INFO)
                        else
                            vim.notify("[move] Failed.", vim.log.levels.ERROR)
                        end
                    end)
                end,
            })
        end, { desc = "Install/reinstall Move tree-sitter parser" })
    end,
}
