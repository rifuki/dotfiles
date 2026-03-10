#!/usr/bin/env bash

width=$(tmux display-message -p '#{client_width}' 2>/dev/null || echo 0)

# Always reserve at least 50 chars for the left (window list) area
left_reserve=50
max_right=120

right_len=$(( width - left_reserve ))
[ "$right_len" -gt "$max_right" ] && right_len=$max_right
[ "$right_len" -lt 0 ] && right_len=0

tmux set -g status-right-length "$right_len"
