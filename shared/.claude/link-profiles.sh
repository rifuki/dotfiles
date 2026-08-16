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
#   ./link-profiles.sh --unlink   # remove the links again (uninstall)
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
# alone.
ASSETS=(CLAUDE.md sounds statusline-command.sh)

# settings.json is seeded, never symlinked. Claude Code writes this file every time you
# touch /config, so a symlink turns every UI change into an edit of a git-tracked file:
# the working tree is permanently dirty and every pull conflicts. It is still shared
# across profiles below — only the repo -> ~/.claude hop is a copy.
#
# The repo copy is a starting point, not the source of truth. Machine-specific keys
# (tui, theme, model, autoCompactEnabled) belong in settings.local.json, which is in
# NEVER above and therefore never shared and never tracked. To publish a change you
# made through the UI, copy it into the repo deliberately.
SEEDED=(settings.json)
REPO_ASSETS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

seed_assets() {
  local item src dst
  for item in "${SEEDED[@]}"; do
    src="$REPO_ASSETS/$item" dst="$CANON/$item"
    [ -e "$src" ] || continue
    if [ -L "$dst" ]; then
      # Migration from the era when this was linked: keep the content, drop the link,
      # so /config stops writing straight into the repo.
      case "$(readlink "$dst")" in
        "$REPO_ASSETS"/*)
          if [ "$1" != dry ]; then rm -f "$dst"; cp "$src" "$dst"; fi
          echo "   $item was a symlink into the repo -> replaced with a real copy" ;;
        *) echo "   $item linked elsewhere — left alone" ;;
      esac
    elif [ ! -e "$dst" ]; then
      [ "$1" = dry ] || cp "$src" "$dst"
      echo "   $item seeded (copy, not a link)"
    else
      echo "   $item already present — left alone (yours is authoritative)"
    fi
  done
}

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
  seed_assets "$1"
  echo
}

mode=link
case "${1-}" in
  --check)   mode=check ;;
  --dry-run) mode=dry ;;
  --unlink)  mode=unlink ;;
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
        # Aimed somewhere other than ~/.claude still resolves, but defeats the point:
        # it puts whatever it points at — usually the repo — back in the write path.
        [ "$(readlink "$p")" = "$CANON/$item" ] || {
          echo "MISAIMED ~${p#$HOME} -> $(readlink "$p")  (expected ~/.claude/$item)"; rc=1
        }
      elif [ -L "$p" ]; then
        echo "BROKEN  ~${p#$HOME} -> $(readlink "$p")"; rc=1
      elif [ -e "$p" ]; then
        echo "UNSHARED ~${p#$HOME} (real file, not linked)"; rc=1
      else
        echo "MISSING ~${p#$HOME}"; rc=1
      fi
    done
  done
  [ $rc -eq 0 ] && echo "OK — ${#profiles[@]} profile(s), all ${#SHARED[@]} items linked to ~/.claude"
  exit $rc
fi

if [ "$mode" = unlink ]; then
  # Remove only the links this script created — anything pointing into the repo or
  # into ~/.claude. Real files are never touched, so your own config survives an
  # uninstall and only the plumbing goes away.
  n=0
  for item in "${ASSETS[@]}"; do
    p="$CANON/$item"
    [ -L "$p" ] && case "$(readlink "$p")" in "$REPO_ASSETS"/*)
      rm -f "$p"; echo "  unlinked ~/.claude/$item"; n=$((n+1)) ;; esac
  done
  for d in "${profiles[@]}"; do
    for item in "${SHARED[@]}"; do
      p="$d/$item"
      [ -L "$p" ] && case "$(readlink "$p")" in "$CANON"/*)
        rm -f "$p"; echo "  unlinked ~${p#$HOME}"; n=$((n+1)) ;; esac
    done
  done
  echo "  $n link(s) removed; ~/.claude itself left intact"
  exit 0
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
      # A symlink is not automatically the *right* symlink. Profiles created before
      # settings.json stopped being a repo asset point straight at ~/.dotfiles, which
      # bypasses the canonical file and puts the repo back in the write path — the
      # exact thing seeding settings.json was meant to stop. Re-aim those.
      if [ "$(readlink "$src")" = "$dst" ]; then
        echo "   $item already linked"
      elif [ "$mode" = dry ]; then
        echo "   would re-aim $item: $(readlink "$src") -> $dst"
      else
        was="$(readlink "$src")"
        rm -f "$src"; ln -s "$dst" "$src"
        echo "   $item re-aimed: ${was/#$HOME/\~} -> ~/.claude/$item"
      fi
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
  echo "Backup: ~${backup#$HOME}"
  echo "Kept per-profile on purpose: ${NEVER[*]}"
  echo "Verify any time with: $0 --check"
fi
