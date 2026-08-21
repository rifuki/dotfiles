-- =============================================================================
--  Layouts and workspace rules
--  https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/
--  https://wiki.hypr.land/Configuring/Layouts/Master-Layout/
--  https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- =============================================================================

hl.config({
    dwindle = {
        -- `pseudotile` is gone: upstream removed it in 0.55 because it had no
        -- effect. Nothing here bound it, so its absence changes nothing.
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },
})

-- "Smart gaps" / "no gaps when only" — uncomment the whole block to use.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
