#!/usr/bin/env bash
# Config that only takes effect while the scripting addition is live.
#
# `yabai --load-sa` restarts Dock in order to inject the payload. Anything set in
# the seconds that follow runs while the SA is down, and yabai drops it silently:
# no error, no log line, it just keeps the default and reports that default back.
# Measured on macOS 26.5.2 after a boot, with the SA correctly loaded:
#
#   yabairc says   focus_follows_mouse autofocus   ->  runtime: disabled
#   yabairc says   active_window_opacity 0.95      ->  runtime: 1.0000
#
# Keeping those settings here lets them be applied twice: inline from yabairc for
# the normal path, and again from the dock_did_restart signal once Dock is back.
# Both are idempotent, so the second pass costs nothing when the first one landed.

yabai -m config focus_follows_mouse     autofocus
yabai -m config window_opacity          on
yabai -m config window_opacity_duration 0.25
yabai -m config active_window_opacity   0.95
yabai -m config normal_window_opacity   0.85
