-- Headless Mason installer.
--
-- mason-lspconfig schedules installs via vim.schedule (queued after init.lua).
-- Our -c script runs after init.lua but BEFORE the event loop, so listeners
-- registered here will catch all package:install:* events when the loop starts.
--
-- No polling needed — we wait via the event counter and quit when pending == 0.

local function log(msg)
    vim.api.nvim_out_write(msg .. "\n")
end

local reg_ok, registry = pcall(require, "mason-registry")
if not reg_ok then
    log("[mason] ERROR: cannot load mason-registry: " .. tostring(registry))
    vim.cmd("qa!")
    return
end

-- ── Event counter ────────────────────────────────────────────────────────────
local pending = 0

local function on_finish(pkg, success)
    pending = pending - 1
    log(("  [mason] %s %s (pending: %d)"):format(success and "✓" or "✗ FAILED", pkg.name, pending))
    if pending == 0 then
        log("[mason] all done")
        vim.schedule(function() vim.cmd("qa!") end)
    end
end

registry:on("package:install:start", function(pkg)
    pending = pending + 1
    log("  [mason] → " .. pkg.name)
end)
registry:on("package:install:success", function(pkg) on_finish(pkg, true) end)
registry:on("package:install:failed",  function(pkg) on_finish(pkg, false) end)

-- ── Force-load mason (belt-and-suspenders if lazy = false somehow missed it) ─
local lazy_ok, lazy = pcall(require, "lazy")
if lazy_ok then pcall(lazy.load, { plugins = { "mason.nvim" } }) end

-- ── Explicitly install formatters (mason-lspconfig only handles LSPs) ────────
registry.refresh(function()
    for _, name in ipairs({ "prettierd", "stylua" }) do
        local ok, pkg = pcall(registry.get_package, name)
        if ok and not pkg:is_installed() then
            pkg:install()
        end
    end
end)

log("[mason] waiting for installs...")

-- ── Fallback: if nothing started after 5s, all packages are already installed ─
vim.defer_fn(function()
    if pending == 0 then
        log("[mason] nothing to install")
        vim.cmd("qa!")
    end
end, 5000)
