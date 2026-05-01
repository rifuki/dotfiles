#!/bin/bash
# Only launch wofi if not already running
if ! pgrep -x wofi >/dev/null; then
    wofi --show drun
fi
