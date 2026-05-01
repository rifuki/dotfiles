#!/usr/bin/env bash
set -euo pipefail

wallpaper_name="${1:-}"
[ -n "$wallpaper_name" ] || exit 1

if [ -f "$wallpaper_name" ]; then
  exec "$HOME/.local/bin/wallpaper-set" "$wallpaper_name"
fi

exec "$HOME/.local/bin/wallpaper-set" "$HOME/.wallpapers/$wallpaper_name"
