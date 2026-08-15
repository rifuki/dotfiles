#!/usr/bin/env bash
# Back up the Claude Code files that must never reach a public repo.
#
# The dotfiles repo carries everything portable. What it deliberately leaves out has
# no home at all otherwise:
#
#   ~/.claude/hooks/            hook scripts, which tend to name real infrastructure
#   ~/.zshrc.local              profile functions and exported MCP credentials
#   ~/.claude*/settings.local.json  per-profile overrides (model, theme, tui)
#
# Lose the disk and those are gone. This copies them somewhere private.
#
#   ./backup-private.sh                  # to iCloud Drive if present
#   ./backup-private.sh /path/to/dest    # anywhere else
#   ./backup-private.sh --restore SRC    # copy back after a reinstall
#
# Copies rather than symlinks on purpose: iCloud evicts files it thinks are cold, and
# a hook or a shell function that silently vanishes at startup is worse than a stale
# backup. Re-run it whenever you change any of these.

set -uo pipefail

ICLOUD="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
DEFAULT_DEST="$ICLOUD/rifuki/claude-private"

restore=0
if [ "${1-}" = "--restore" ]; then restore=1; shift; fi
DEST="${1-$DEFAULT_DEST}"

collect() {                       # prints: <label> <absolute source path>
  [ -d "$HOME/.claude/hooks" ] && echo "hooks $HOME/.claude/hooks"
  [ -f "$HOME/.zshrc.local" ]   && echo "zshrc.local $HOME/.zshrc.local"
  for d in "$HOME"/.claude "$HOME"/.claude-*/; do
    d="${d%/}"
    [ -f "$d/settings.local.json" ] && echo "$(basename "$d").settings.local.json $d/settings.local.json"
  done
}

if [ "$restore" = 1 ]; then
  [ -d "$DEST" ] || { echo "nothing to restore from: $DEST" >&2; exit 1; }
  echo "restoring from ${DEST/#$HOME/~}"
  [ -d "$DEST/hooks" ] && { mkdir -p "$HOME/.claude"; cp -R "$DEST/hooks" "$HOME/.claude/"; echo "  ~/.claude/hooks"; }
  [ -f "$DEST/zshrc.local" ] && { cp "$DEST/zshrc.local" "$HOME/.zshrc.local"; echo "  ~/.zshrc.local"; }
  for f in "$DEST"/*.settings.local.json; do
    [ -e "$f" ] || continue
    prof="$(basename "$f" .settings.local.json)"
    [ -d "$HOME/$prof" ] && { cp "$f" "$HOME/$prof/settings.local.json"; echo "  ~/$prof/settings.local.json"; }
  done
  echo "done — check ~/.zshrc.local before trusting its exports"
  exit 0
fi

mkdir -p "$DEST" || { echo "cannot write to $DEST" >&2; exit 1; }
n=0
while read -r label src; do
  [ -n "$label" ] || continue
  if [ -d "$src" ]; then rm -rf "${DEST:?}/$label"; cp -R "$src" "$DEST/$label"
  else cp "$src" "$DEST/$label"; fi
  printf '  %-42s %s\n' "${src/#$HOME/~}" "$(du -sh "$DEST/$label" | cut -f1)"
  n=$((n+1))
done < <(collect)

# These carry live credentials, so keep them unreadable by anyone else on the box.
chmod -R go-rwx "$DEST" 2>/dev/null

echo "$n item(s) -> ${DEST/#$HOME/~}"
echo "Restore with: $0 --restore \"$DEST\""
