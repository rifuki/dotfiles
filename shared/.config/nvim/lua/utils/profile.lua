local M = {}

-- Minimal mode: lightweight environments (VPS, Debian) that don't need heavy tools.
-- Auto-detected from /etc/debian_version, or forced via NVIM_MINIMAL=1.
M.is_minimal = vim.fn.filereadable("/etc/debian_version") == 1
    or os.getenv("NVIM_MINIMAL") == "1"

return M
