-- Headless Mason installer.

local function log(msg)
    vim.api.nvim_out_write(msg .. "\n")
end

-- ── Registry ────────────────────────────────────────────────────────────────
local reg_ok, registry = pcall(require, "mason-registry")
if not reg_ok then
    log("[mason] ERROR: cannot load mason-registry: " .. tostring(registry))
    vim.cmd("qa!")
    return
end

-- ── Event listeners (for logging + catching installs triggered AFTER this script) ─
registry:on("package:install:start",   function(pkg) log("  [mason] → " .. pkg.name) end)
registry:on("package:install:success", function(pkg) log("  [mason] ✓ " .. pkg.name) end)
registry:on("package:install:failed",  function(pkg) log("  [mason] ✗ FAILED: " .. pkg.name) end)

-- ── Force-load mason (lazy = false should handle this, but belt-and-suspenders) ─
local lazy_ok, lazy = pcall(require, "lazy")
if lazy_ok then
    pcall(lazy.load, { plugins = { "mason.nvim" } })
end

-- ── Diagnostics ─────────────────────────────────────────────────────────────
local mason_loaded = vim.fn.exists(":Mason") == 2
log("[mason] mason commands registered: " .. tostring(mason_loaded))
if not mason_loaded then
    -- Last resort: call setup directly so installs can proceed
    log("[mason] falling back to direct mason.setup()")
    local m_ok, mason = pcall(require, "mason")
    if m_ok then pcall(mason.setup) end
    local ml_ok, mlsp = pcall(require, "mason-lspconfig")
    if ml_ok then
        local p_ok, profile = pcall(require, "utils.profile")
        local is_minimal = p_ok and profile.is_minimal or false
        local lsps = {
            "lua_ls", "taplo", "ts_ls", "denols", "intelephense",
            "dockerls", "yamlls", "gh_actions_ls", "jsonls",
            "cssls", "html", "bashls", "clangd",
        }
        if not is_minimal then
            vim.list_extend(lsps, { "prismals", "solidity_ls_nomicfoundation", "tailwindcss" })
        end
        pcall(mlsp.setup, {
            ensure_installed = lsps,
            automatic_installation = true,
            automatic_enable = { exclude = { "taplo", "move_analyzer" } },
        })
    end
end

log("[mason] waiting for installs...")

-- ── Poll ─────────────────────────────────────────────────────────────────────
-- rawget(pkg, "handle") is non-nil while installing, nil when done
local idle = 0
local function poll()
    local busy = false
    for _, pkg in ipairs(registry.get_all_packages()) do
        if rawget(pkg, "handle") then busy = true; break end
    end
    if busy then
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
