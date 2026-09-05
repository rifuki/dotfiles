# Claude Code

The gate. Both halves live elsewhere, and nothing but this file is Claude-specific.

@~/.dotfiles/shared/agents/AGENTS.md
@~/.config/agents/PRIVATE.md
@~/brain/RULES.md

The first is public and shared with every other agent on this machine; the second is
private and reached only by path. Claude Code is the only one here that expands an
import. Codex, pi and Copilot CLI read a merged copy built by
`~/.config/agents/build.sh`, and opencode is handed both paths in its own config.

## Gaya tulis

Jangan pernah pakai em dash (U+2014, si garis panjang penghubung) di teks apa pun:
jawaban, commit, file, catatan. Terbaca AI banget. Pakai koma, titik dua, tanda kurung,
atau pecah jadi kalimat terpisah.
Aturan bahasa selengkapnya di `~/brain/RULES.md`.
