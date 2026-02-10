-- return {
--     "mrcjkb/rustaceanvim",
--     version = "^5",
--     lazy = false,
--     config = function()
--         vim.g.rustaceanvim = {
--             -- Plugin configuration
--             tools = {},
--             -- LSP configuration
--             server = {
--                 on_attach = function(client, bufnr)
--                     vim.lsp.inlay_hint.enable(false)
--                 end,
--                 default_settings = {
--                     -- rust-analyzer language server configuration
--                     ["rust-analyzer"] = {
--                         cargo = {
--                             allFeatures = true, -- Disable for faster startup (especially anchor)
--                             -- target = "x86_64-unknown-linux-gnu", -- Set target to avoid freeze
--
--                             -- Enable build script support
--                             buildScripts = {
--                                 enable = false, -- Disable for faster startup
--                             },
--                         },
--                         -- check = {
--                         --     command = "clippy",
--                         --     extraArgs = { "--target", "x86_64-unknown-linux-gnu" },
--                         -- },
--                         -- Enable more Rust-analyzer features
--                         procMacro = {
--                             enable = true,
--                             attributes = {
--                                 enable = true,
--                             },
--                         },
--                         cachePriming = {
--                             enable = false, -- Disable to reduce CPU usage
--                         },
--                         diagnostics = {
--                             disabled = {
--                                 "unresolved-proc-macro",
--                                 "unresolved-macro-call",
--                             },
--                         },
--                         inlayHints = {
--                             bindingModeHints = { enable = true },
--                             chainingHints = { enable = true },
--                             closingBraceHints = { enable = true, minLines = 25 },
--                             lifetimeElisionHints = { enable = true, useParameterNames = true },
--                             parameterHints = { enable = true },
--                             typeHints = { enable = true },
--                         },
--                     },
--                 },
--             },
--             -- DAP configuration
--             dap = {},
--         }
--     end,
-- }

return {
  "mrcjkb/rustaceanvim",
  version = "^5",
  lazy = false,
  ["rust-analyzer"] = {
    cargo = {
      allFeatures = true
    }
  }
}
