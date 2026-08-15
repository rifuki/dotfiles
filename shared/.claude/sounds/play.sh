#!/bin/sh
# Play a notification sound for a Claude Code hook event.
#
# Usage: play.sh <event>          (event = stop | fail | permission | subagent)
#
# Custom sounds: drop a file named <event>.<ext> in this directory and it wins
# over the built-in default. Supported: aiff wav mp3 m4a caf.
#   ~/.claude/sounds/stop.mp3        -> plays on every finished turn
#   ~/.claude/sounds/permission.wav  -> plays when a permission prompt appears
#
# Mute everything:   touch ~/.claude/sounds/mute
# Mute one event:    touch ~/.claude/sounds/subagent.mute
# Unmute:            rm ~/.claude/sounds/mute
# Volume (0.0-2.0):  echo 0.4 > ~/.claude/sounds/volume

DIR="$HOME/.claude/sounds"

# Hooks pipe JSON on stdin; drain it so the writer never sees a broken pipe.
[ -t 0 ] || cat >/dev/null 2>&1

event="$1"
[ -n "$event" ] || exit 0
[ -f "$DIR/mute" ] && exit 0
[ -f "$DIR/$event.mute" ] && exit 0

vol=$(cat "$DIR/volume" 2>/dev/null)
case "$vol" in
  ''|*[!0-9.]*) vol=1 ;;
esac

sound=''
for ext in aiff wav mp3 m4a caf; do
  if [ -f "$DIR/$event.$ext" ]; then
    sound="$DIR/$event.$ext"
    break
  fi
done

if [ -z "$sound" ]; then
  case "$event" in
    stop)       sound=/System/Library/Sounds/Glass.aiff ;;
    fail)       sound=/System/Library/Sounds/Basso.aiff ;;
    permission) sound=/System/Library/Sounds/Tink.aiff ;;
    subagent)   sound=/System/Library/Sounds/Pop.aiff ;;
    *)          sound=/System/Library/Sounds/Glass.aiff ;;
  esac
fi

# Detach so the hook returns instantly and the sound survives the parent exiting.
nohup afplay -v "$vol" "$sound" >/dev/null 2>&1 &
exit 0
