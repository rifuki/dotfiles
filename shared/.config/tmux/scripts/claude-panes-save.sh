#!/bin/sh
# tmux-resurrect post-save-layout hook. A saved Claude pane says only "claude", which
# restores as a new conversation; this rewrites it to resume the one the pane holds.
file=$1
[ -f "$file" ] || exit 0
sessions=${CLAUDE_SESSIONS_DIR:-$HOME/.claude/sessions}
map=$(mktemp) || exit 0
trap 'rm -f "$map" "$map.out"' EXIT

tmux list-panes -a -F '#{session_name}	#{window_index}	#{pane_index}	#{pane_pid}' |
  while IFS='	' read -r session window pane shell; do
    # ps, not pgrep: pgrep leaves out its own ancestors, and its flags differ between systems.
    for pid in $(ps -axo pid=,ppid= | awk -v parent="$shell" '$2 == parent { print $1 }'); do
      [ -f "$sessions/$pid.json" ] || continue
      id=$(sed -n 's/.*"sessionId" *: *"\([^"]*\)".*/\1/p' "$sessions/$pid.json" | head -1)
      [ -n "$id" ] || continue
      # The profile is the process's config directory: ~/.claude-NAME, or none for the default.
      dir=$(ps eww -o command= -p "$pid" | tr ' ' '\n' | sed -n 's/^CLAUDE_CONFIG_DIR=//p' | head -1)
      case $dir in
        */.claude-*) profile=${dir##*/.claude-} ;;
        *) profile=default ;;
      esac
      printf '%s\t%s\t%s\t%s\t%s\n' "$session" "$window" "$pane" "$profile" "$id" >>"$map"
      break
    done
  done

[ -s "$map" ] || exit 0
# Bytes, not characters: a pane title may hold anything.
LC_ALL=C awk -F '\t' -v OFS='\t' -v map="$map" '
  BEGIN {
    while ((getline line < map) > 0) {
      split(line, f, "\t")
      resume[f[1] SUBSEP f[2] SUBSEP f[3]] = ":~/.config/tmux/scripts/claude-resume.sh " f[4] " " f[5]
    }
  }
  $1 == "pane" && (($2, $3, $6) in resume) { $11 = resume[$2, $3, $6] }
  { print }
' "$file" >"$map.out" && cat "$map.out" >"$file"
