# Claude Code

The gate. Both halves live elsewhere, and nothing but this file is Claude-specific.

@~/.dotfiles/shared/agents/AGENTS.md
@~/.config/agents/PRIVATE.md

The first is public and shared with every other agent on this machine; the second is
private and reached only by path. Claude Code is the only one here that expands an
import — Codex, pi and Copilot CLI read a merged copy built by
`~/.config/agents/build.sh`, and opencode is handed both paths in its own config.
