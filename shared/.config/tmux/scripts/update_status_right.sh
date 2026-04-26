#!/usr/bin/env bash

width=$(tmux display-message -p '#{client_width}' 2>/dev/null || true)

case "$width" in
  ''|*[!0-9]*) exit 0 ;;
esac

[ "$width" -le 0 ] && exit 0

# Prioritize window list: hide status-right if terminal too small
min_width=100  # Minimum terminal width to show status-right
left_reserve=60
max_right=80

if [ "$width" -lt "$min_width" ]; then
  # Hide status-right completely on small terminals
  tmux set-option -gq status-right-length 0
else
  right_len=$(( width - left_reserve ))
  [ "$right_len" -gt "$max_right" ] && right_len=$max_right
  [ "$right_len" -lt 0 ] && right_len=0
  tmux set-option -gq status-right-length "$right_len"
fi
