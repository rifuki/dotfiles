-- Headless Mason installer: waits for all package installs to complete before quitting.
--
-- Two sources of installs:
--   1. mason-lspconfig ensure_installed → triggered during init.lua (before this script runs)
--   2. MasonInstallAll → triggered after this script via -c "+MasonInstallAll"
--
-- Strategy: attach to handles already in-flight, then listen for any new ones.

local registry = require("mason-registry")
local pending = 0

local function on_done()
    pending = pending - 1
    if pending == 0 then
        vim.schedule(function() vim.cmd("qa!") end)
    end
end

-- Attach to packages already being installed (started by mason-lspconfig during init.lua)
for _, pkg in ipairs(registry.get_all_packages()) do
    local handle = pkg:get_handle()
    if handle and not handle:is_closed() then
        pending = pending + 1
        handle:on("closed", on_done)
    end
end

-- Attach to any new installs triggered after this script (e.g. MasonInstallAll)
registry:on("package:install:start", function(pkg)
    pending = pending + 1
    local handle = pkg:get_handle()
    if handle then
        handle:on("closed", on_done)
    else
        on_done()
    end
end)

-- Fallback: if nothing is installing at all, quit after 3s
vim.defer_fn(function()
    if pending == 0 then vim.cmd("qa!") end
end, 3000)
