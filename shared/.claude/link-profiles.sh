#!/usr/bin/env bash
# Share one Claude Code state directory across several accounts.
#
# Claude Code keeps everything for one account under a config dir chosen by
# CLAUDE_CONFIG_DIR (default ~/.claude). Running a second account means a second
# dir — and with it a second copy of your skills, plugins, hooks, transcripts and
# memory, plus a separate peer registry so the sessions cannot see each other.
#
# This script points the shareable parts of every ~/.claude-<name>/ profile at the
# canonical ~/.claude/, so the accounts stay separate but the workspace is one.
#
#   ./link-profiles.sh            # link everything (merges first, never clobbers)
#   ./link-profiles.sh --check    # report only, change nothing
#   ./link-profiles.sh --dry-run  # show what would happen
#
# Safe to re-run. Anything it replaces is moved to a timestamped backup dir.

set -uo pipefail

CANON="$HOME/.claude"

# Shared: content you want identical everywhere.
#   sessions  peer registry — the reason cross-account `ListAgents` works at all
#   projects  transcripts AND memory/ (memory lives under projects/<slug>/memory)
#   skills    installed skills
#   plugins   installed plugins
#   settings  hooks, statusline, permissions, model defaults
#   CLAUDE.md global instructions
SHARED=(sessions projects skills plugins settings.json CLAUDE.md)

# Never shared. .claude.json holds oauthAccount — a single field naming the active
# account — and Claude Code rewrites the whole file constantly. Sharing it makes the
# last writer overwrite every other account's identity, and two concurrent sessions
# can corrupt it outright. settings.local.json is the per-profile override that keeps
# model/theme/tui personal even though settings.json is shared. history.jsonl is
# append-only from several processes at once, so interleaved writes are possible.
readonly NEVER=(.claude.json .credentials.json settings.local.json history.jsonl)

# Assets this repo ships for ~/.claude. Linked in only when it is safe: missing,
# already linked, or byte-identical. Anything that has diverged is reported and left
# alone — settings.json in particular drifts as you change things through the UI, and
# the copy in the repo is usually the older one.
ASSETS=(CLAUDE.md sounds statusline-command.sh settings.json)
REPO_ASSETS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install_assets() {
  local item src dst
  echo "== repo assets -> ~/.claude"
  for item in "${ASSETS[@]}"; do
    src="$REPO_ASSETS/$item" dst="$CANON/$item"
    [ -e "$src" ] || continue
    if [ -L "$dst" ]; then
      echo "   $item already linked"
    elif [ ! -e "$dst" ]; then
      [ "$1" = dry ] || ln -s "$src" "$dst"
      echo "   $item linked"
    elif diff -rq "$src" "$dst" >/dev/null 2>&1; then
      if [ "$1" != dry ]; then mv "$dst" "$backup/canon-$item"; ln -s "$src" "$dst"; fi
      echo "   $item identical -> linked"
    else
      echo "   $item DIVERGED — left alone (yours is authoritative; copy it into the repo yourself if you want it tracked)"
    fi
  done
  echo
}

mode=link
case "${1-}" in
  --check)   mode=check ;;
  --dry-run) mode=dry ;;
  --help|-h) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  "")        ;;
  *)         echo "unknown option: $1 (try --help)" >&2; exit 2 ;;
esac

# A profile is a ~/.claude-<name>/ that has its own .claude.json. That test is what
# keeps backup dirs such as ~/.claude-profile-backup-20260816 from being treated as
# profiles.
profiles=()
for d in "$HOME"/.claude-*/; do
  d="${d%/}"
  [ -f "$d/.claude.json" ] && profiles+=("$d")
done

if [ ${#profiles[@]} -eq 0 ]; then
  echo "No extra profiles found. Create one with:"
  echo "  CLAUDE_CONFIG_DIR=~/.claude-work ANTHROPIC_NO_KEYCHAIN=1 claude   # then /login"
  exit 0
fi

if [ "$mode" = check ]; then
  rc=0
  for d in "${profiles[@]}"; do
    for item in "${SHARED[@]}"; do
      p="$d/$item"
      if [ -L "$p" ] && [ -e "$p" ]; then
        :
      elif [ -L "$p" ]; then
        echo "BROKEN  ${p/#$HOME/\~} -> $(readlink "$p")"; rc=1
      elif [ -e "$p" ]; then
        echo "UNSHARED ${p/#$HOME/\~} (real file, not linked)"; rc=1
      else
        echo "MISSING ${p/#$HOME/\~}"; rc=1
      fi
    done
  done
  [ $rc -eq 0 ] && echo "OK — ${#profiles[@]} profile(s), all ${#SHARED[@]} items linked to ~/.claude"
  exit $rc
fi

backup="$HOME/.claude-profile-backup-$(date +%Y%m%d-%H%M%S)"
[ "$mode" = link ] && mkdir -p "$backup"

install_assets "$mode"

for d in "${profiles[@]}"; do
  name="$(basename "$d")"
  echo "== $name"
  for item in "${SHARED[@]}"; do
    src="$d/$item" dst="$CANON/$item"

    if [ -L "$src" ]; then
      echo "   $item already linked"
      continue
    fi

    if [ "$mode" = dry ]; then
      if [ -e "$src" ]; then echo "   would merge + link $item"
      else echo "   would link $item"; fi
      continue
    fi

    # Merge whatever this profile already has into the canonical dir first, so
    # nothing is lost. -n never overwrites an existing file: the canonical copy
    # always wins, and same-named-but-different files stay behind in the backup
    # for you to reconcile by hand.
    if [ -e "$src" ]; then
      if [ -d "$src" ]; then
        mkdir -p "$dst"
        cp -Rn "$src"/. "$dst"/ 2>/dev/null
      elif [ ! -e "$dst" ]; then
        cp -n "$src" "$dst"
      fi
      mv "$src" "$backup/$name-${item//\//_}"
    fi

    ln -s "$dst" "$src"
    echo "   $item -> ~/.claude/$item"
  done
done

if [ "$mode" = link ]; then
  rmdir "$backup" 2>/dev/null && backup="(nothing needed backing up)"
  echo
  echo "Backup: ${backup/#$HOME/\~}"
  echo "Kept per-profile on purpose: ${NEVER[*]}"
  echo "Verify any time with: $0 --check"
fi
