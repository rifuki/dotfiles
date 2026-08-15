#!/usr/bin/env bash
# Restart yabai when its resident memory crosses a threshold.
#
# yabai leaks steadily — on this setup roughly 100-130 MB per hour, so an
# uninterrupted day reaches 2-3 GB. `yabai --restart-service` brings it back to
# ~30 MB and preserves the window layout, so the cheap fix is to do that on a
# threshold rather than on a schedule: no restart while it is behaving, and no
# unbounded growth when it is not.
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
