-- =============================================================================
--  Keybindings
--  https://wiki.hypr.land/Configuring/Basics/Binds/
--  https://wiki.hypr.land/Configuring/Basics/Dispatchers/
-- =============================================================================
--  Shape changes from hyprlang:
--    bind  = MOD, KEY, dispatcher   ->  hl.bind("MOD + KEY", hl.dsp.<...>())
--    binde = ...                    ->  opts { repeating = true }
--    bindl = ...                    ->  opts { locked = true }
--    bindel = ...                   ->  opts { locked = true, repeating = true }
--    bindm = ...                    ->  opts { mouse = true }
--
--  $HOME no longer expands on its own: hyprlang's `exec` handed the string to a
--  shell, so `$HOME/...` worked implicitly. hl.exec_cmd makes no such promise, so
--  paths are built from os.getenv("HOME") and anything needing real shell syntax
--  (pipes, command substitution) is wrapped in `sh -lc` explicitly.
-- =============================================================================

local programs = require("conf/programs")

local home = os.getenv("HOME")
local bin  = home .. "/.local/bin/"

local superMod = "SUPER"
local ctrlMod  = "CTRL"
local altMod   = "ALT"

-- ── Basic app controls (macOS style) ─────────────────────────────────────────
hl.bind(superMod .. " + Q", hl.dsp.window.close())  -- Quit app
hl.bind(superMod .. " + W", hl.dsp.window.close())  -- Close window

-- ── System ───────────────────────────────────────────────────────────────────
hl.bind(ctrlMod .. " + " .. altMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(ctrlMod .. " + " .. altMod .. " + S", hl.dsp.exec_cmd("systemctl suspend"))
hl.bind(superMod .. " + SHIFT + Q", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/hypr-logout.sh"))

-- ── Floating / grid / fullscreen ─────────────────────────────────────────────
hl.bind(superMod .. " + return", hl.dsp.exec_cmd(bin .. "float-toggle"))     -- toggle float, 900x600 + center
hl.bind(superMod .. " + V",      hl.dsp.exec_cmd(bin .. "clipboard-paste"))  -- clipboard picker + auto-paste
hl.bind(superMod .. " + F",      hl.dsp.exec_cmd(bin .. "zoom-toggle"))      -- zoom-fullscreen, yabai-style
hl.bind(altMod   .. " + F",      hl.dsp.exec_cmd(bin .. "zoom-toggle"))

-- True fullscreen (hides waybar). hyprlang `fullscreen, 0` meant mode 0, which
-- is full fullscreen rather than maximize.
hl.bind(superMod .. " + SHIFT + F",      hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(superMod .. " + SHIFT + RETURN", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

-- Left as a shelled-out hyprctl chain on purpose: it is three dispatches in
-- sequence, and hl.bind takes a single dispatcher.
hl.bind(superMod .. " + " .. altMod .. " + SPACE", hl.dsp.exec_cmd(
    "sh -lc 'hyprctl dispatch togglefloating; hyprctl dispatch resizeactive exact 900 600; hyprctl dispatch movewindowpixel center'"))

-- ── Resize floating ──────────────────────────────────────────────────────────
local resizeStep = 40
hl.bind(superMod .. " + " .. ctrlMod .. " + H", hl.dsp.window.resize({ x = -resizeStep, y = 0, relative = true }), { repeating = true })
hl.bind(superMod .. " + " .. ctrlMod .. " + L", hl.dsp.window.resize({ x =  resizeStep, y = 0, relative = true }), { repeating = true })
hl.bind(superMod .. " + " .. ctrlMod .. " + K", hl.dsp.window.resize({ x = 0, y = -resizeStep, relative = true }), { repeating = true })
hl.bind(superMod .. " + " .. ctrlMod .. " + J", hl.dsp.window.resize({ x = 0, y =  resizeStep, relative = true }), { repeating = true })

-- ── Split ────────────────────────────────────────────────────────────────────
-- togglesplit is a layout message, not a standalone dispatcher.
hl.bind(superMod .. " + E", hl.dsp.layout("togglesplit"))

-- ── Window focus ─────────────────────────────────────────────────────────────
hl.bind(superMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(superMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(superMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(superMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- ── Swap windows ─────────────────────────────────────────────────────────────
hl.bind(superMod .. " + SHIFT + H", hl.dsp.window.swap({ direction = "left" }))
hl.bind(superMod .. " + SHIFT + J", hl.dsp.window.swap({ direction = "down" }))
hl.bind(superMod .. " + SHIFT + K", hl.dsp.window.swap({ direction = "up" }))
hl.bind(superMod .. " + SHIFT + L", hl.dsp.window.swap({ direction = "right" }))

-- ── Workspaces (macOS Mission Control style) ─────────────────────────────────
hl.bind(superMod .. " + TAB", hl.dsp.focus({ workspace = "previous" }))
hl.bind(superMod .. " + P",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(superMod .. " + N",   hl.dsp.focus({ workspace = "e+1" }))

-- Workspaces 1..10, where 10 sits on key 0 — same mapping as the old explicit
-- twenty lines, expressed as a loop.
for i = 1, 10 do
    local key = i % 10
    hl.bind(superMod .. " + " .. key,             hl.dsp.focus({ workspace = i }))
    hl.bind(superMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- ── Special workspace (scratchpad) ───────────────────────────────────────────
hl.bind(superMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(superMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- ── Screenshots ──────────────────────────────────────────────────────────────
-- The first two pipe into wl-copy and the second substitutes $(slurp), so both
-- genuinely need a shell.
hl.bind("Print",         hl.dsp.exec_cmd([[sh -lc 'grim -l 0 - | wl-copy']]))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd([[sh -lc 'grim -l 0 -g "$(slurp)" - | wl-copy']]))
hl.bind(superMod .. " + Print",         hl.dsp.exec_cmd(bin .. "screenshot-copy"))
hl.bind(superMod .. " + SHIFT + Print", hl.dsp.exec_cmd(bin .. "screenshot-area-copy"))

-- ── Mouse ────────────────────────────────────────────────────────────────────
hl.bind(superMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(superMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ── Laptop media and brightness keys ─────────────────────────────────────────
local lockedRepeat = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), lockedRepeat)
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      lockedRepeat)
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     lockedRepeat)
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   lockedRepeat)
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  lockedRepeat)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  lockedRepeat)

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- ── App shortcuts ────────────────────────────────────────────────────────────
-- Spotlight-style launcher on three different modifiers, as before.
hl.bind(ctrlMod  .. " + SPACE", hl.dsp.exec_cmd(programs.menu))
hl.bind(superMod .. " + SPACE", hl.dsp.exec_cmd(programs.menu))
hl.bind(altMod   .. " + SPACE", hl.dsp.exec_cmd(programs.menu))

hl.bind(superMod .. " + Y",  hl.dsp.exec_cmd(bin .. "wallpaper-picker"))
hl.bind(superMod .. " + X",  hl.dsp.exec_cmd(bin .. "actions"))
hl.bind(superMod .. " + F5", hl.dsp.exec_cmd("sh -lc 'toggle-theme'"))  -- dark/light, resolved via PATH

hl.bind(ctrlMod .. " + " .. altMod .. " + T", hl.dsp.exec_cmd(programs.terminal))
hl.bind(ctrlMod .. " + " .. altMod .. " + E", hl.dsp.exec_cmd(programs.fileManager))
