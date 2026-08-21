-- =============================================================================
--  Programs — consumed by conf/keybinds.lua
-- =============================================================================
--  In hyprlang these were $terminal / $fileManager / $menu, which were global
--  string substitutions. Lua has no such thing: require() gives each file its
--  own scope, so this module returns a table and keybinds.lua requires it.
-- =============================================================================

return {
    terminal    = "ghostty",
    fileManager = "dolphin",
    menu        = "fuzzel",
}
