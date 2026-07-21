#!/bin/zsh

# Navigasi display cyclic sesuai posisi FISIK (urutan baca: atas->bawah, kiri->kanan).
# Robust ke susunan horizontal MAUPUN vertical; wrap di ujung.
# Buat 2 monitor, prev & next sama-sama loncat ke monitor satunya (wajar).
# $1 = focus | move   (fokus display, atau pindahin window aktif ke display)
# $2 = next  | prev

action="$1"; dir="$2"

# daftar index display terurut posisi fisik (y dulu -> x)
displays=($(yabai -m query --displays | jq -r 'sort_by(.frame.y, .frame.x) | .[].index'))
cur=$(yabai -m query --displays --display | jq -r '.index')
n=${#displays[@]}

[[ "$n" -lt 2 ]] && exit 0

# posisi (1-based) display aktif dalam urutan
idx=1
for i in {1..$n}; do
  [[ "${displays[$i]}" == "$cur" ]] && { idx=$i; break; }
done

# target dengan wrap
if [[ "$dir" == "next" ]]; then
  target=$(( idx % n + 1 ))
else
  target=$(( (idx - 2 + n) % n + 1 ))
fi
tdisp="${displays[$target]}"

if [[ "$action" == "move" ]]; then
  yabai -m window --display "$tdisp" --focus
else
  yabai -m display --focus "$tdisp"
fi

~/.config/yabai/warp_display.sh
