#!/bin/sh
# Claude Code hook: claude-state.sh busy|wait|idle|clear. Always exits 0.
[ -n "$TMUX_PANE" ] || exit 0
command -v tmux >/dev/null 2>&1 || exit 0
if [ "$1" = clear ]; then
  tmux set -wu -t "$TMUX_PANE" @claude_state 2>/dev/null
else
  state=$1
  # done = finished while you were elsewhere
  if [ "$state" = idle ] && [ "$(tmux display -p -t "$TMUX_PANE" '#{&&:#{window_active},#{session_attached}}' 2>/dev/null)" != 1 ]; then
    state=done
  fi
  tmux set -w -t "$TMUX_PANE" @claude_state "$state" 2>/dev/null
fi
cat >/dev/null 2>&1
exit 0
