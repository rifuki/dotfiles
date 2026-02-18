-- Load NvChad LSP defaults (capabilities, on_attach, etc.)
require("nvchad.configs.lspconfig").defaults()

-- Load all LSP configurations
require("configs.lsp.defaults")
require("configs.lsp.web")
require("configs.lsp.yaml")
require("configs.lsp.prisma")
require("configs.lsp.move")
require("configs.lsp.solidity")
require("configs.lsp.php")
