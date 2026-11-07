#!/bin/sh
# Current Music/Spotify track, cached 3 s; never launches the apps.
c=/tmp/.tmux-np-$(id -u)
if [ -n "$(find "$c" -mtime -3s 2>/dev/null)" ]; then cat "$c"; exit 0; fi
out=""
for app in Music Spotify; do
  pgrep -xq "$app" || continue
  out=$(osascript -e "tell application \"$app\" to if player state is playing then return (name of current track) & \" · \" & (artist of current track)" 2>/dev/null)
  [ -n "$out" ] && break
done
if [ ${#out} -gt 34 ]; then out="$(printf '%s' "$out" | cut -c1-33)…"; fi
printf '%s' "$out" > "$c"
printf '%s' "$out"
