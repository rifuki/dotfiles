#!/bin/bash
# Simple script to show Cloudflare WARP status for Waybar

STATUS=$(warp-cli status 2>/dev/null)

# If the status string contains "Connected", show an icon/text
if echo "$STATUS" | grep -q "Connected"; then
  # output in JSON for Waybar custom module
  echo "{\"text\":\"󰅟  WARP\",\"tooltip\":\"$STATUS\"}"
else
  # output nothing = module disappears
  echo ""
fi
