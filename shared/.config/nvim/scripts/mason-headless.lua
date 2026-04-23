-- Headless Mason installer: waits for all package installs to complete before quitting.

local function log(msg)
    vim.api.nvim_out_write(msg .. "\n")
end

-- Force-load mason in headless mode (Lazy won't load it without a buffer event)
local ok, lazy = pcall(require, "lazy")
if ok then
    lazy.load({ plugins = { "mason.nvim" } })
end

local registry_ok, registry = pcall(require, "mason-registry")
if not registry_ok then
    log("[mason] ERROR: cannot load mason-registry: " .. tostring(registry))
    vim.cmd("qa!")
    return
end

log("[mason] starting headless install...")

local pending = 0
local total = 0

local function on_done(pkg_name, success)
    pending = pending - 1
    local status = success and "✓" or "✗ FAILED"
    log(("  [mason] %s %s (%d/%d)"):format(status, pkg_name, total - pending, total))
    if pending == 0 then
        log("[mason] all done")
        vim.schedule(function() vim.cmd("qa!") end)
    end
end

local function attach(pkg)
    local handle = pkg:get_handle()
    if not handle or handle:is_closed() then return end
    pending = pending + 1
    total = total + 1
    log("  [mason] installing " .. pkg.name .. "...")
    handle:on("closed", function()
        vim.schedule(function()
            on_done(pkg.name, pkg:is_installed())
        end)
    end)
end

-- Attach to packages already being installed (started by mason-lspconfig during init.lua)
for _, pkg in ipairs(registry.get_all_packages()) do
    attach(pkg)
end

-- Attach to any new installs triggered after this script (e.g. MasonInstallAll)
registry:on("package:install:start", function(pkg)
    attach(pkg)
end)

-- Fallback: if nothing is installing, quit after 3s
vim.defer_fn(function()
    if pending == 0 then
        log("[mason] nothing to install")
        vim.cmd("qa!")
    end
end, 3000)
