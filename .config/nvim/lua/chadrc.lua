-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}

M.base46 = {
    transparency = true,

    -- hl_override = {
    -- 	Comment = { italic = true },
    -- 	["@comment"] = { italic = true },
    -- },
}

-- M.nvdash = { load_on_startup = true }
M.ui = {
    tabufline = {
        lazyload = false,
    },
    statusline = {
        enabled = true,
        theme = "minimal",
        separator_style = "default",
        modules = {
            mode = function()
                local utils = require("nvchad.stl.utils")
                if not utils.is_activewin() then return "" end

                local m = vim.api.nvim_get_mode().mode
                local mode_info = utils.modes[m]
                local sep = utils.separators["default"]
                local sep_r = "%#St_sep_r#" .. sep["right"] .. " %#ST_EmptySpace#"

                local has_nerd = vim.g.have_nerd_font ~= false
                local icon = has_nerd and vim.fn.nr2char(0xF0AD8) or "𐰁"

                return "%#St_" .. mode_info[2] .. "ModeSep#"
                    .. sep["left"]
                    .. "%#St_" .. mode_info[2] .. "Mode#"
                    .. icon .. " "
                    .. "%#St_" .. mode_info[2] .. "ModeText#"
                    .. " " .. mode_info[1]
                    .. sep_r
            end,
        },
    },
}

pcall(require, "custom.icons")

return M
