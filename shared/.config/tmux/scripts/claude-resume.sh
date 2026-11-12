#!/bin/sh
# Resumes one Claude Code conversation under the profile it was held in.
# usage: claude-resume.sh PROFILE SESSION_ID   (default, or NAME for ~/.claude-NAME)
profile=$1
id=$2
[ -n "$id" ] || { echo "usage: claude-resume.sh PROFILE SESSION_ID" >&2; exit 2; }
if [ "$profile" = default ]; then
  unset CLAUDE_CONFIG_DIR ANTHROPIC_NO_KEYCHAIN
else
  export CLAUDE_CONFIG_DIR="$HOME/.claude-$profile" ANTHROPIC_NO_KEYCHAIN=1
fi
exec "${CLAUDE_BIN:-$(command -v claude || echo "$HOME/.bun/bin/claude")}" --resume "$id"
