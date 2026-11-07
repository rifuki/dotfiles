#!/bin/sh
# cpu and mem meters; mem counts like Activity Monitor.
cores=$(sysctl -n hw.ncpu)
cpu=$(ps -A -o %cpu= | awk -v n="$cores" '{s+=$1} END {v=s/n; if (v>100) v=100; printf "%d", v+0.5}')
mem=$(vm_stat | awk -v total="$(sysctl -n hw.memsize)" '
  /page size of/ {ps=$8} /Anonymous pages/ {a=$3} /Pages wired down/ {w=$4}
  /occupied by compressor/ {c=$5} /Pages purgeable/ {p=$3}
  END {printf "%d", (a-p+w+c)*ps*100/total + 0.5}')
lvl=$(sysctl -n kern.memorystatus_vm_pressure_level 2>/dev/null || echo 1)
meter() { # value hot
  n=$(( ($1 + 10) / 20 )); [ $n -gt 5 ] && n=5
  col="#00c8eb"; [ "$2" = 1 ] && col="#ff5ab9"
  on=""; off=""; i=0
  while [ $i -lt 5 ]; do if [ $i -lt $n ]; then on="${on}━"; else off="${off}━"; fi; i=$((i+1)); done
  printf '#[fg=%s]%s#[fg=#3b4a54]%s #[fg=#c8d3d5]%s%%' "$col" "$on" "$off" "$1"
}
hotc=0; [ "$cpu" -ge 80 ] && hotc=1
hotm=0; [ "$lvl" -ge 2 ] && hotm=1
printf '#[fg=#00c8eb]  '; meter "$cpu" $hotc
printf '    #[fg=#00c8eb]  '; meter "$mem" $hotm
