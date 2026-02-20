#!/usr/bin/env bash
# Network speed for macOS and Linux
# Usage: net_speed.sh [download|upload|max]

MODE="${1:-max}"
OS="$(uname)"

# Get default interface
if [ "$OS" = "Darwin" ]; then
  INTERFACE=$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')
else
  INTERFACE=$(ip route 2>/dev/null | awk '/^default/{print $5; exit}')
fi
[ -z "$INTERFACE" ] && echo "0 B/s" && exit 0

CACHE_DIR="${TMPDIR:-/tmp}/tmux-net-speed"
mkdir -p "$CACHE_DIR"

get_bytes() {
  local mode="$1"
  local cache="$CACHE_DIR/${INTERFACE}_${mode}"
  local timef="$CACHE_DIR/${INTERFACE}_${mode}_time"

  local now prev_time prev_bytes curr_bytes diff bytes
  now=$(date +%s)
  prev_time=$(cat "$timef" 2>/dev/null || echo "$now")
  prev_bytes=$(cat "$cache" 2>/dev/null || echo 0)

  if [ "$OS" = "Darwin" ]; then
    curr_bytes=$(netstat -ib 2>/dev/null | awk -v iface="$INTERFACE" -v m="$mode" '
      $1 == iface && /Link/ { print (m == "download") ? $7 : $10; exit }
    ')
  else
    curr_bytes=$(awk -v iface="$INTERFACE:" -v m="$mode" '
      $1 == iface { print (m == "download") ? $2 : $10; exit }
    ' /proc/net/dev 2>/dev/null)
  fi

  echo "$now" > "$timef"
  echo "$curr_bytes" > "$cache"

  diff=$(( now - prev_time ))
  [ "$diff" -le 0 ] && diff=1
  bytes=$(( (curr_bytes - prev_bytes) / diff ))
  [ "$bytes" -lt 0 ] && bytes=0
  echo "$bytes"
}

fmt() {
  local b="$1"
  if   [ "$b" -ge 1073741824 ]; then printf "%.1f GB/s" "$(echo "$b 1073741824" | awk '{printf "%.1f",$1/$2}')";
  elif [ "$b" -ge 1048576 ];    then printf "%.1f MB/s" "$(echo "$b 1048576"    | awk '{printf "%.1f",$1/$2}')";
  elif [ "$b" -ge 1024 ];       then printf "%.0f KB/s" "$(echo "$b 1024"       | awk '{printf "%.0f",$1/$2}')";
  else printf "%d B/s" "$b"; fi
}

if [ "$MODE" = "max" ]; then
  dl=$(get_bytes download)
  ul=$(get_bytes upload)
  if [ "$dl" -ge "$ul" ]; then
    printf "󰇚 %s" "$(fmt "$dl")"
  else
    printf "󰕒 %s" "$(fmt "$ul")"
  fi
else
  bytes=$(get_bytes "$MODE")
  fmt "$bytes"
fi
