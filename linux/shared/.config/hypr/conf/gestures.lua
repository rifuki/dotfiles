-- =============================================================================
--  Gestures — trackpad and touchscreen
--  https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
-- =============================================================================

-- ── Hyprland built-in ────────────────────────────────────────────────────────
-- hyprlang was: gesture = 4, horizontal, workspace
hl.gesture({
    fingers   = 4,
    direction = "horizontal",
    action    = "workspace",
})

-- The workspace_swipe_* tuning survived the Lua migration as a config section
-- (HL.ConfigOpt.Gestures), so all of these carry over unchanged.
hl.config({
    gestures = {
        workspace_swipe_distance                 = 300,
        workspace_swipe_invert                   = true,
        workspace_swipe_min_speed_to_force       = 30,
        workspace_swipe_cancel_ratio             = 0.5,
        workspace_swipe_create_new               = true,
        workspace_swipe_direction_lock           = true,
        workspace_swipe_direction_lock_threshold = 10,
        workspace_swipe_touch                    = true, -- touchscreen swipe too
    },
})

-- ── hyprgrass plugin — touchscreen ───────────────────────────────────────────
-- Resolved at runtime against the loaded plugin. Neither of the two candidates
-- that used to sit here was right, and the reason is worth keeping:
--
--   * The old `plugin { touch_gestures { ... } }` block registers through
--     HyprlandAPI::addConfigValue, which Hyprland hard-gates to the legacy
--     config parser. On a Lua config it silently registers nothing, so every
--     option reads back as "no such option" and the plugin runs on defaults.
--   * The namespace is `hyprgrass`, not `touch_gestures`.
--   * hyprgrass exposes a Lua API instead: hl.plugin.hyprgrass.{gesture,bind}.
--
-- Verify any change with:
--     hyprctl getoption plugin:hyprgrass:sensitivity   -> float: 4.000000
hl.config({
    plugin = {
        hyprgrass = {
            sensitivity                 = 4.0,  -- upstream recommends 4.0 for tablet screens
            long_press_delay            = 400,
            edge_margin                 = 10,
            resize_on_border_long_press = true,
        },
    },
})

-- Touchscreen workspace swipe.
--
-- Hyprland's built-in workspace_swipe_touch above only covers a ONE-finger drag
-- that STARTS within (gaps_out + border_size) px of the screen edge — 22px on
-- this 1920px panel — so multi-finger swiping anywhere on the glass has to come
-- from hyprgrass.
--
-- `workspace` rejects direction "swipe"; it needs an axis, hence "horizontal".
hl.plugin.hyprgrass.gesture({
    pattern = { kind = "swipe", fingers = 3, direction = "horizontal" },
    action  = "workspace",
})

hl.plugin.hyprgrass.gesture({
    pattern = { kind = "swipe", fingers = 4, direction = "horizontal" },
    action  = "workspace",
})
