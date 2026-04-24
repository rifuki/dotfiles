-- Headless Mason installer.
--
-- mason-lspconfig.setup() triggers LSP installs during init.lua (lazy=false on mason.nvim).
-- Formatters are not handled by mason-lspconfig, so we install them explicitly here.
-- Polling via rawget(pkg, "handle") catches all in-flight installs regardless of timing.

local function log(msg)
    vim.api.nvim_out_write(msg .. "\n")
end

local reg_ok, registry = pcall(require, "mason-registry")
if not reg_ok then
    log("[mason] ERROR: cannot load mason-registry: " .. tostring(registry))
    vim.cmd("qa!")
    return
end

-- Log all install events for visibility
registry:on("package:install:start",   function(pkg) log("  [mason] → " .. pkg.name) end)
registry:on("package:install:success", function(pkg) log("  [mason] ✓ " .. pkg.name) end)
registry:on("package:install:failed",  function(pkg) log("  [mason] ✗ FAILED: " .. pkg.name) end)

-- Explicitly install formatters (mason-lspconfig only handles LSPs)
local formatters = { "prettierd", "stylua" }
registry.refresh(function()
    for _, name in ipairs(formatters) do
        local ok, pkg = pcall(registry.get_package, name)
        if ok and not pkg:is_installed() then
            pkg:install()
        end
    end
end)

log("[mason] waiting for installs...")

-- Poll every 2s using registry.get_installing_packages() — the proper Mason API.
-- Confirm 2× (4s) that nothing is running before quitting.
local idle = 0
local function poll()
    local installing = registry.get_installing_packages()
    if #installing > 0 then
        idle = 0
        vim.defer_fn(poll, 2000)
    elseif idle < 2 then
        idle = idle + 1
        vim.defer_fn(poll, 2000)
    else
        log("[mason] all done")
        vim.cmd("qa!")
    end
end

vim.defer_fn(poll, 3000)
