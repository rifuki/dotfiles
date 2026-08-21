-- =============================================================================
--  Input — keyboard, touchpad, per-device overrides
--  https://wiki.hypr.land/Configuring/Basics/Variables/
--  https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/
-- =============================================================================
--  Note the touchpad option names: hyprlang spelled several with hyphens
--  (tap-to-click, tap-and-drag), which are not valid bare Lua table keys. The
--  Lua API uses underscores throughout — verified against
--  HL.ConfigOpt.Input.Touchpad in /usr/share/hypr/stubs/hl.meta.lua.
-- =============================================================================

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        repeat_rate  = 70,   -- key repeat speed (chars/sec)
        repeat_delay = 150,  -- delay before repeat starts (ms)

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 to 1.0, 0 means no modification

        touchpad = {
            natural_scroll          = true,  -- macOS-style scrolling
            scroll_factor           = 0.4,   -- scroll sensitivity
            middle_button_emulation = false,
            tap_to_click            = true,  -- was tap-to-click
            tap_and_drag            = true,  -- was tap-and-drag
            drag_lock               = false,
            disable_while_typing    = true,
            clickfinger_behavior    = true,  -- 2-finger = right, 3-finger = middle
        },
    },
})

-- ── Per-device overrides ─────────────────────────────────────────────────────
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})

hl.device({
    name         = "ydotoold-virtual-device",
    accel_profile = "flat",
    sensitivity  = 0,
})
