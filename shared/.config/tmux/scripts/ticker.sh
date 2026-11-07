#!/bin/bash
# Pushes 5 fps animation frames (#() jobs only refresh once a second).
pidf="/tmp/.tmux-ticker-$(id -u)"
if [ -f "$pidf" ] && kill -0 "$(cat "$pidf")" 2>/dev/null; then exit 0; fi
echo $$ > "$pidf"
spin=("·" "✢" "✳" "✶" "✻" "✽" "✻" "✶" "✳" "✢")
dance=("♪ヽ(•ᴗ•)ノ " " ヾ(•ᴗ•)ゞ♫" "♫＼(˘ᴗ˘)／ " " ヽ(•ᴗ•)ノ♪" "♪ヾ(•ᴗ<)ゞ " " ＼(•ᴗ•)／♫")
doze=(" ＿(-ᴗ-)＿z" " ＿(-ᴗ-)＿z" " ＿(-ᴗ-)＿Z" " ＿(-ᴗ-)＿Z" " ＿(˘ᴗ˘)＿ " " ＿(˘ᴗ˘)＿ ")
np="$HOME/.config/tmux/scripts/now-playing.sh"
i=0
while tmux has-session 2>/dev/null; do
  [ $((i % 15)) -eq 0 ] && playing=$("$np")
  busy=$(tmux list-windows -a -F '#{@claude_state}' 2>/dev/null | grep -cE 'busy|wait')
  if [ -n "$playing" ]; then m=${dance[$(( (i / 2) % 6 ))]}; else m=${doze[$(( (i / 4) % 6 ))]}; fi
  b="●"; [ $(( (i / 3) % 2 )) -eq 1 ] && b="○"
  tmux set -gq @spin "${spin[$((i % 10))]}" \; set -gq @miku "$m" \; set -gq @blink "$b"
  if [ "$busy" -gt 0 ] || [ -n "$playing" ] || [ $((i % 4)) -eq 0 ]; then
    for c in $(tmux list-clients -F '#{client_name}' 2>/dev/null); do tmux refresh-client -S -t "$c" 2>/dev/null; done
  fi
  i=$((i + 1))
  sleep 0.2
done
rm -f "$pidf"
