-- =============================================================================
--  Autostart — plugin load and startup commands
--  https://wiki.hypr.land/Configuring/Basics/Autostart/
-- =============================================================================
--  hyprlang used `exec-once = ...` lines. The Lua equivalent is subscribing to
--  the hyprland.start event and calling hl.exec_cmd there, which is what upstream
--  does in example/hyprland.lua.
--
--  Trailing `&` from the old exec-once lines is dropped: hl.exec_cmd does not
--  block, so backgrounding was already redundant. Anything needing shell syntax
--  (pipes, &&, $HOME expansion) is wrapped in `sh -lc` explicitly, because
--  hl.exec_cmd is not guaranteed to hand the string to a shell.
-- =============================================================================

-- Hyprland plugins are ABI-locked to the exact compositor version, so this .so
-- must be rebuilt after every Hyprland upgrade or it refuses to load (and the
-- touch_gestures settings in conf/gestures.lua go inert with it).
--
-- Built 2026-08-17 against Hyprland 0.56.2 (efb50993) from hyprgrass main @ 56473e9.
-- There is no usable tagged release: the newest, v0.8.2, is from Oct 2024 and
-- predates the Lua config rewrite, so it cannot build against 0.56.x.
--
-- Rebuild:
--   git clone https://github.com/horriblename/hyprgrass /tmp/hyprgrass-build
--   mkdir -p /tmp/pcshim && ln -sf /usr/lib64/pkgconfig/lua5.4.pc /tmp/pcshim/lua.pc
--   PKG_CONFIG_PATH=/tmp/pcshim:/usr/lib64/pkgconfig \
--     meson setup /tmp/hyprgrass-build/build /tmp/hyprgrass-build --buildtype=release
--   ninja -C /tmp/hyprgrass-build/build
--   install -m755 /tmp/hyprgrass-build/build/src/libhyprgrass.so ~/.local/share/hypr/plugins/
-- The pcshim exists because Gentoo ships lua5.4.pc, while hyprgrass asks for lua.pc.
hl.plugin.load(os.getenv("HOME") .. "/.local/share/hypr/plugins/libhyprgrass.so")

hl.on("hyprland.start", function()
    -- Hand the Wayland/Hyprland environment to the user systemd session and to
    -- D-Bus activation, so services started later inherit it.
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("systemctl --user restart xdg-desktop-portal-hyprland xdg-desktop-portal")

    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("sh -lc 'sleep 3 && nmcli dev wifi rescan'")
    hl.exec_cmd("waybar")
    hl.exec_cmd("sh -lc '$HOME/.local/bin/wallpaper-daemon'")
    hl.exec_cmd("dunst")
    hl.exec_cmd("copyq")
    hl.exec_cmd("sh -lc '$HOME/.local/bin/three-finger-drag'")
    hl.exec_cmd("hyprctl setcursor theme_miku-cursor 24")
end)
