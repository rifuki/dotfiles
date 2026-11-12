#!/bin/sh
# tmux-resurrect post-save-all hook: puts the last save back when its link points at nothing.
dir=${1:-$HOME/.local/share/tmux/resurrect}
[ -L "$dir/last" ] && [ ! -e "$dir/last" ] && [ -f "$dir/.last-save" ] || exit 0
cp "$dir/.last-save" "$dir/$(readlink "$dir/last")"
