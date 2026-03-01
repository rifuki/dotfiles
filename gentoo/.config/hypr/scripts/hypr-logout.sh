#!/bin/bash
# hyprland-logout.sh
# Cleans up Hyprland runtime dirs and exits

# Kill Hyprland cleanly
pkill -TERM Hyprland

# Remove leftover runtime directories
rm -rf /run/user/$(id -u)/hypr/*
