#!/usr/bin/env bash
set -euo pipefail

wallpaper_name="${1:-}"
[ -n "$wallpaper_name" ] || exit 1

if [ -f "$wallpaper_name" ]; then
  exec rifuki-wallpaper-set "$wallpaper_name"
fi

exec rifuki-wallpaper-set "$HOME/.wallpapers/$wallpaper_name"
