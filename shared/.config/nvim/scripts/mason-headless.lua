-- Headless Mason installer.
--
-- Problem: mason-lspconfig triggers installs during init.lua (before -c commands run),
-- so event-based listeners miss the "install:start" signals.
-- Solution: combine event listeners (for logging + new installs) with polling
-- (rawget(pkg, "handle") to detect in-flight installs regardless of when they started).

local function log(msg)
    vim.api.nvim_out_write(msg .. "\n")
end

local reg_ok, registry = pcall(require, "mason-registry")
if not reg_ok then
    log("[mason] ERROR: cannot load mason-registry: " .. tostring(registry))
    vim.cmd("qa!")
    return
end

-- Log new installs for visibility
registry:on("package:install:start",   function(pkg) log("  [mason] → " .. pkg.name) end)
registry:on("package:install:success", function(pkg) log("  [mason] ✓ " .. pkg.name) end)
registry:on("package:install:failed",  function(pkg) log("  [mason] ✗ FAILED: " .. pkg.name) end)

-- Force-load mason.nvim via Lazy (runs config → mason.setup + mason-lspconfig.setup).
-- If already loaded this is a no-op; if not, this triggers the ensure_installed installs.
local lazy_ok, lazy = pcall(require, "lazy")
if lazy_ok then
    lazy.load({ plugins = { "mason.nvim" } })
end

log("[mason] waiting for installs...")

-- Poll every 2s. rawget(pkg, "handle") is non-nil while a package is installing
-- (mason sets pkg.handle = nil on completion), so this catches both pre-existing
-- in-flight installs and ones triggered by the lazy.load above.
local idle = 0
local function poll()
    local busy = false
    for _, pkg in ipairs(registry.get_all_packages()) do
        if rawget(pkg, "handle") then
            busy = true
            break
        end
    end
    if busy then
        idle = 0
        vim.defer_fn(poll, 2000)
    elseif idle < 2 then
        -- confirm twice (4s) that nothing is installing before quitting
        idle = idle + 1
        vim.defer_fn(poll, 2000)
    else
        log("[mason] all done")
        vim.cmd("qa!")
    end
end

-- Initial delay: give mason-lspconfig time to queue installs after lazy.load
vim.defer_fn(poll, 3000)
