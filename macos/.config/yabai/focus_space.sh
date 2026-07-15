#!/bin/zsh

# Fokus space next/prev TAPI cuma di dalam display yang lagi aktif.
# Gak nyebrang monitor; mentok di ujung -> wrap ke ujung lain (dalam display sama).
# $1 = next | prev

dir="$1"

# daftar index space di display yg lagi fokus + space yg lagi fokus
spaces=($(yabai -m query --spaces --display | jq -r '.[].index'))
cur=$(yabai -m query --spaces --space | jq -r '.index')
n=${#spaces[@]}

# cari posisi (1-based) space aktif di dalam array
idx=1
for i in {1..$n}; do
  [[ "${spaces[$i]}" == "$cur" ]] && { idx=$i; break; }
done

# hitung target (wrap dalam display)
if [[ "$dir" == "next" ]]; then
  target=$(( idx % n + 1 ))
else
  target=$(( (idx - 2 + n) % n + 1 ))
fi

yabai -m space --focus "${spaces[$target]}"
