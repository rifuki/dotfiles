return {
    "3rd/image.nvim",
    lazy = false,
    config = function()
        local home = os.getenv("HOME")
        package.path = package.path .. ";" .. home .. "/.luarocks/share/lua/5.1/?.lua;" .. home .. "/.luarocks/share/lua/5.1/?/init.lua"
        package.cpath = package.cpath .. ";" .. home .. "/.luarocks/lib/lua/5.1/?.so"

        local ffi = require("ffi")
        pcall(function()
            ffi.load("/opt/homebrew/lib/libMagickWand-7.Q16HDRI.dylib")
        end)

        require("image").setup({
            backend = "kitty",
            integrations = {
                markdown = {
                    enabled = true,
                    clear_in_insert_mode = false,
                    download_remote_images = true,
                    only_render_image_at_cursor = false,
                    floating_windows = false,
                },
            },
            max_width = nil,
            max_height = nil,
            max_width_window_percentage = nil,
            max_height_window_percentage = 50,
            window_overlap_clear_enabled = true,
            window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
            editor_only_render_when_focused = true,
            tmux_show_only_in_active_window = true,
            hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
        })

        -- Clear images when nvim loses focus (works with tmux focus-events on)
        vim.api.nvim_create_autocmd({ "FocusLost", "VimLeavePre" }, {
            callback = function()
                require("image").clear()
            end,
        })
    end,
}
