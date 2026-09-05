# Claude Code

The gate. Both halves live elsewhere, and nothing but this file is Claude-specific.

@~/.dotfiles/shared/agents/AGENTS.md
@~/.config/agents/PRIVATE.md
@~/brain/RULES.md

The first is public and shared with every other agent on this machine; the second is
private and reached only by path. Claude Code is the only one here that expands an
import. Codex, pi and Copilot CLI read a merged copy built by
`~/.config/agents/build.sh`, and opencode is handed both paths in its own config.

## Writing style

Never use the em dash (U+2014, the long connecting dash) in any text: replies, commits,
files, notes. It reads as AI-generated. Use commas, colons, parentheses, or separate
sentences instead. Full language rules live in `~/brain/RULES.md`.
