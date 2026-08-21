-- =============================================================================
--  Window rules
--  https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- =============================================================================
--  Shape changes from hyprlang:
--    match:class = ^(...)$   ->  match = { class = "^(...)$" }
--    size = 760 560          ->  size = {760, 560}          (a table, not a pair
--                                of bare numbers)
--    move = onscreen A B     ->  move = {"expr", "expr"}     (`onscreen` and the
--                                `%` shorthand are hyprlang-only and are gone;
--                                the expression form replaces them)
-- =============================================================================

hl.window_rule({
    name  = "popup-float-center",
    match = { class = "^(wallpaper-picker|actions|power-menu)$" },
    float  = true,
    center = true,
})

hl.window_rule({
    name  = "wallpaper-picker-size",
    match = { class = "^(wallpaper-picker)$" },
    size  = {760, 560},
})

hl.window_rule({
    name  = "actions-size",
    match = { class = "^(actions)$" },
    size  = {420, 560},
})

hl.window_rule({
    name  = "power-menu-size",
    match = { class = "^(power-menu)$" },
    size  = {360, 370},
})

-- macOS-like temporary screenshot thumbnail. Matched on class and on title,
-- because the helper sets whichever the toolkit exposes.
--
-- The old rule was `move = onscreen 100%-w-24 77%`. Translated to expressions:
--   100%-w-24  ->  monitor_w - window_w - 24
--   77%        ->  monitor_h * 0.77
-- The result is inside the monitor by construction, so dropping `onscreen`
-- clamping costs nothing here.
local thumbnailPlacement = {
    float = true,
    pin   = true,
    size  = {326, 246},
    move  = {"monitor_w - window_w - 24", "monitor_h * 0.77"},
}

hl.window_rule({
    name  = "screenshot-thumbnail",
    match = { class = "^(floating-screenshot|screenshot-thumbnail)$" },
    float = thumbnailPlacement.float,
    pin   = thumbnailPlacement.pin,
    size  = thumbnailPlacement.size,
    move  = thumbnailPlacement.move,
})

hl.window_rule({
    name  = "screenshot-thumbnail-title",
    match = { title = "^(floating-screenshot|screenshot-thumbnail)$" },
    float = thumbnailPlacement.float,
    pin   = thumbnailPlacement.pin,
    size  = thumbnailPlacement.size,
    move  = thumbnailPlacement.move,
})

-- Example
-- hl.window_rule({ match = { class = "^(kitty)$", title = "^(kitty)$" }, float = true })
