#!/bin/sh
# Swap the notification sound for a Claude Code hook event.
#
# Usage:
#   set.sh <event> <myinstants-url | direct-url | local-file>   install a sound
#   set.sh list                                                 show what is installed
#   set.sh play <event>                                         preview a sound
#   set.sh reset <event>                                        drop back to the system default
#
# Events: stop (turn finished) | permission (Claude asks) | fail | subagent
#
# Examples:
#   set.sh stop https://www.myinstants.com/en/instant/mikudayooooooo-50628/
#   set.sh permission ~/Downloads/beep.wav
#   set.sh reset fail

DIR="$HOME/.claude/sounds"
EVENTS="stop permission fail subagent"
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36"

die() { printf '%s\n' "$*" >&2; exit 1; }

valid_event() {
  for e in $EVENTS; do [ "$1" = "$e" ] && return 0; done
  return 1
}

# Path of the custom file currently installed for an event, if any.
current() {
  for ext in aiff wav mp3 m4a caf; do
    [ -f "$DIR/$1.$ext" ] && { printf '%s' "$DIR/$1.$ext"; return 0; }
  done
  return 1
}

cmd_list() {
  for e in $EVENTS; do
    f=$(current "$e") || f=''
    if [ -n "$f" ]; then
      printf '%-11s %s\n' "$e" "${f##*/}"
    else
      printf '%-11s (system default)\n' "$e"
    fi
    [ -f "$DIR/$e.mute" ] && printf '%-11s   ^ muted\n' ''
  done
  [ -f "$DIR/mute" ] && printf '\nall sounds are muted (rm %s/mute to unmute)\n' "$DIR"
  vol=$(cat "$DIR/volume" 2>/dev/null) && [ -n "$vol" ] && printf '\nvolume: %s\n' "$vol"
  return 0
}

cmd_install() {
  event="$1"; src="$2"
  valid_event "$event" || die "unknown event '$event' (use: $EVENTS)"
  [ -n "$src" ] || die "usage: set.sh $event <url-or-file>"

  tmp=$(mktemp -d) || die "cannot create temp dir"
  trap 'rm -rf "$tmp"' EXIT
  audio="$tmp/dl"

  case "$src" in
    http://*|https://*)
      url="$src"
      # A myinstants page: pull the real media URL out of the HTML.
      case "$url" in
        *myinstants.com*instant*)
          media=$(curl -sL -A "$UA" "$url" \
            | grep -o "/media/sounds/[A-Za-z0-9._%-]*" | head -1)
          [ -n "$media" ] || die "could not find a sound on that myinstants page"
          referer="$url"
          url="https://www.myinstants.com$media"
          ;;
        *) referer="$url" ;;
      esac
      curl -fsSL -A "$UA" -e "$referer" "$url" -o "$audio" \
        || die "download failed: $url"
      name="${url##*/}"
      ;;
    *)
      [ -f "$src" ] || die "no such file: $src"
      cp "$src" "$audio" || die "cannot read $src"
      name="${src##*/}"
      ;;
  esac

  # Extension from the source name, defaulting to mp3.
  ext=$(printf '%s' "$name" | tr 'A-Z' 'a-z' | sed -n 's/.*\.\(aiff\|wav\|mp3\|m4a\|caf\)$/\1/p')
  [ -n "$ext" ] || ext=mp3

  file "$audio" | grep -qiE 'audio|mpeg|iso media|wave|aiff' \
    || die "that does not look like an audio file: $(file -b "$audio")"

  # Only one custom file per event may exist, else play.sh picks by ext order.
  for old in aiff wav mp3 m4a caf; do
    [ -f "$DIR/$event.$old" ] && mv "$DIR/$event.$old" "$DIR/$event.$old.bak"
  done

  cp "$audio" "$DIR/$event.$ext" || die "cannot write $DIR/$event.$ext"
  printf 'installed %s -> %s.%s\n' "$name" "$event" "$ext"
  cmd_play "$event"
}

cmd_play() {
  valid_event "$1" || die "unknown event '$1' (use: $EVENTS)"
  /bin/sh "$DIR/play.sh" "$1" </dev/null
}

cmd_reset() {
  valid_event "$1" || die "unknown event '$1' (use: $EVENTS)"
  f=$(current "$1") || die "$1 already uses the system default"
  mv "$f" "$f.bak"
  printf 'reset %s to the system default (old file kept at %s.bak)\n' "$1" "${f##*/}"
}

case "$1" in
  ''|list|-h|--help|help) [ "$1" = list ] && cmd_list || { sed -n '2,15p' "$0" | cut -c3-; echo; cmd_list; } ;;
  play)  cmd_play "$2" ;;
  reset) cmd_reset "$2" ;;
  *)     cmd_install "$1" "$2" ;;
esac
