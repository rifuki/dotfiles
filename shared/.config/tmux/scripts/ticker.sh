#!/bin/bash
# Pushes 5 fps animation frames (#() jobs only refresh once a second).
# One tmux call per frame; window states and clients are re-read once a second.
pidf="/tmp/.tmux-ticker-$(id -u)"
if [ -f "$pidf" ] && kill -0 "$(cat "$pidf")" 2>/dev/null; then exit 0; fi
echo $$ > "$pidf"
spin=("·" "✢" "✳" "✶" "✻" "✽" "✻" "✶" "✳" "✢")
ocspin=("▘" "▝" "▗" "▖")
dance=("♪ヽ(•ᴗ•)ノ " " ヾ(•ᴗ•)ゞ♫" "♫＼(˘ᴗ˘)／ " " ヽ(•ᴗ•)ノ♪" "♪ヾ(•ᴗ<)ゞ " " ＼(•ᴗ•)／♫")
doze=(" ＿(-ᴗ-)＿z" " ＿(-ᴗ-)＿z" " ＿(-ᴗ-)＿Z" " ＿(-ᴗ-)＿Z" " ＿(˘ᴗ˘)＿ " " ＿(˘ᴗ˘)＿ ")
np="$HOME/.config/tmux/scripts/now-playing.sh"
meters="$HOME/.config/tmux/scripts/meters.sh"
save="$HOME/.config/tmux/plugins/tmux-resurrect/scripts/save.sh"
export METER_NCPU=$(sysctl -n hw.ncpu) METER_MEM=$(sysctl -n hw.memsize)
i=0
busy=0
clients=()
while :; do
  if [ $((i % 5)) -eq 0 ]; then
    out=$(tmux list-windows -a -F 'W#{@claude_state}' \; list-clients -F 'C#{client_name}' 2>/dev/null) || break
    busy=0; clients=()
    while IFS= read -r l; do
      case $l in
        Wbusy|Wwait) busy=$((busy + 1)) ;;
        C*) clients+=("${l#C}") ;;
      esac
    done <<< "$out"
  fi
  [ $((i % 15)) -eq 0 ] && playing=$("$np")
  [ $((i % 10)) -eq 0 ] && mt=$("$meters")
  # resurrect auto-save every 5 min, replacing continuum's per-second check
  [ $i -gt 0 ] && [ $((i % 1500)) -eq 0 ] && { "$save" quiet >/dev/null 2>&1 & }
  if [ -n "$playing" ]; then m=${dance[$(( (i / 2) % 6 ))]}; else m=${doze[$(( (i / 4) % 6 ))]}; fi
  b="●"; [ $(( (i / 3) % 2 )) -eq 1 ] && b="○"
  cmd=(set -gq @spin "${spin[$((i % 10))]}" \; set -gq @ocspin "${ocspin[$(( (i / 2) % 4 ))]}" \; set -gq @miku "$m" \; set -gq @blink "$b" \; set -gq @meters "$mt")
  if [ "$busy" -gt 0 ] || [ -n "$playing" ] || [ $((i % 4)) -eq 0 ]; then
    for c in "${clients[@]}"; do cmd+=(\; refresh-client -S -t "$c"); done
  fi
  tmux "${cmd[@]}" 2>/dev/null
  i=$((i + 1))
  sleep 0.2
done
rm -f "$pidf"
