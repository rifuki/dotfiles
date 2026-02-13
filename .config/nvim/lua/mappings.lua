require("nvchad.mappings")

-- add yours here

local map = vim.keymap.set

map("n", ":", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
map("n", "<leader>nd", "<cmd>NoiceDismiss<CR>", { desc = "Dismiss Noice Message" })
map("i", "<C-s>", vim.lsp.buf.signature_help, { silent = true })
map("n", "q", "<Nop>", { noremap = true, silent = true })
-- map("n", "<leader>fm", function()
--   require("conform").format()
-- end, { desc = "Format with Prettier" })
map("n", "<leader>fm", function()
    require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format file" })

map("n", "<leader>rc", function()
    vim.cmd("enew | setlocal textwidth=72 wrap spell")
    vim.api.nvim_create_autocmd("TextYankPost", {
        buffer = 0,
        callback = function()
            vim.cmd("normal! ggVGgq")
        end,
        once = true,
    })
end, { desc = "New commit buffer + auto wrap after paste" })

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
