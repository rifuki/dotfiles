#!/usr/bin/env bash
# Restart yabai when its resident memory crosses a threshold.
#
# yabai grows with window-event load, not with uptime. Measured on this machine:
# 130-160 MB/hour through a busy stretch of many terminals opening and closing,
# then 29 MB after 8.5 hours of light use — no drift at all. So a nightly restart
# would fire on the quiet days and still let a busy afternoon run away.
#
# A threshold handles both: nothing happens while yabai is behaving, and a busy
# spell gets capped wherever it lands. `yabai --restart-service` returns it to
# ~30 MB and keeps the window layout, so the restart itself costs nothing.
#
#   memory-guard.sh              # check once, restart if over the limit
#   memory-guard.sh --status     # print current usage and do nothing
#   YABAI_RSS_LIMIT_MB=600 ...   # override the default limit
#
# Run it from launchd; see dev.dotfiles.yabai-memory-guard.plist next to this file.

set -uo pipefail

LIMIT_MB="${YABAI_RSS_LIMIT_MB:-500}"
LOG="${TMPDIR:-/tmp}/yabai-memory-guard.log"

pid="$(pgrep -x yabai | head -1)"
if [ -z "$pid" ]; then
  [ "${1-}" = --status ] && echo "yabai is not running"
  exit 0
fi

# ps reports RSS in KiB.
rss_mb=$(( $(ps -o rss= -p "$pid" | tr -d ' ') / 1024 ))

if [ "${1-}" = --status ]; then
  echo "yabai pid $pid: ${rss_mb} MB (limit ${LIMIT_MB} MB)"
  exit 0
fi

if [ "$rss_mb" -ge "$LIMIT_MB" ]; then
  yabai --restart-service
  sleep 2
  new_pid="$(pgrep -x yabai | head -1)"
  new_mb=0
  [ -n "$new_pid" ] && new_mb=$(( $(ps -o rss= -p "$new_pid" | tr -d ' ') / 1024 ))
  printf '%s restarted yabai at %s MB -> %s MB\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "$rss_mb" "$new_mb" >> "$LOG"
fi
