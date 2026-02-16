#!/bin/bash
# Toggle Ghostty background-opacity between 0.65 (transparent) and 1.0 (opaque)
CONFIG="$HOME/.config/ghostty/config"

if grep -q "^background-opacity = 1\.0" "$CONFIG" 2>/dev/null; then
  sed -i '' 's/^background-opacity = 1\.0/background-opacity = 0.65/' "$CONFIG"
else
  sed -i '' 's/^background-opacity = [0-9.]*/background-opacity = 1.0/' "$CONFIG"
fi
