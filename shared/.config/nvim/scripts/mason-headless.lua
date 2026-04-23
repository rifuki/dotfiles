-- Headless Mason installer: waits for all package installs to complete before quitting.
--
-- Two sources of installs:
--   1. mason-lspconfig ensure_installed → triggered during init.lua (before this script runs)
--   2. MasonInstallAll → triggered after this script via -c "+MasonInstallAll"
--
-- Strategy: attach to handles already in-flight, then listen for any new ones.

local registry = require("mason-registry")
local pending = 0
local total = 0

local function log(msg)
    io.write(msg .. "\n")
    io.flush()
end

local function on_done(pkg_name, success)
    pending = pending - 1
    if success then
        log("  [mason] ✓ " .. pkg_name .. " (" .. (total - pending) .. "/" .. total .. ")")
    else
        log("  [mason] ✗ " .. pkg_name .. " FAILED (" .. (total - pending) .. "/" .. total .. ")")
    end
    if pending == 0 then
        log("  [mason] all done")
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

-- Fallback: if nothing is installing at all, quit after 3s
vim.defer_fn(function()
    if pending == 0 then
        log("  [mason] nothing to install")
        vim.cmd("qa!")
    end
end, 3000)
