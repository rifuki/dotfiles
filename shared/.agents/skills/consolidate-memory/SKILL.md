---
name: consolidate-memory
description: Audit and consolidate the persistent memory store (MEMORY.md + memory/*.md) — merge overlapping facts, retire resolved/superseded ones, shorten over-long entries, and clean the index. Use when the memory store has grown noisy, has duplicates, or after a burst of memory writes; not for writing a single new memory (do that inline).
argument-hint: "[optional: scope hint — a slug, keyword, or 'all'] [mode:headless]"
---

# Consolidate Memory

Keep the persistent memory store lean and trustworthy. Memory loads in two stages: **`MEMORY.md` (the index) auto-loads every session** — one line per file, so it must stay tight; **each file's body is only recalled on relevance**, so over-long or stale files quietly cost context when they surface. This skill audits the store and applies the cleanup.

**Operate on the memory directory named in your system prompt's "Memory" section** (the absolute path for the active config/project — do NOT guess or hardcode `.claude` vs `.claude-monklabs`; use the one given to this session). All edits stay in that one store.

## Mode Detection

If `$ARGUMENTS` contains `mode:headless`, strip it and run **headless** (no questions; apply only unambiguous actions; report at the end). Otherwise run **interactive** (confirm deletes/merges). A remaining argument is a scope hint (a slug, keyword, or `all`); default to `all`.

## Steps

1. **Load.** Read `MEMORY.md` and every `*.md` in the memory dir. Note each file's `name`, `description`, `metadata.type`, body length, and `[[links]]`.

2. **Classify** each memory into exactly one action:
   - **Keep** — one clear, still-true fact; body reasonably short. Leave it.
   - **Shorten** — accurate but bloated (multi-topic, long transcripts of detail). Trim to the durable fact + why/how; move deep detail to the repo doc it references (link to it) instead of holding it in memory.
   - **Consolidate** — two+ files cover the same subject. Merge into the best-named one, union the facts, fix `[[links]]`, delete the others.
   - **Retire** — the fact is resolved, superseded, or no longer true (e.g. a "drift" fixed, a handoff replaced by a newer one, a flag/file that no longer exists). Delete it.

3. **Verify before retiring or trusting.** A memory reflects what was true when written. Before deleting or relying on one, confirm against ground truth — the repo, git log, or the live file/flag it names. Never retire a fact you cannot confirm is actually resolved; if unsure, downgrade to Shorten and add a "verify:" note rather than delete.

4. **Apply.**
   - Rewrite Shorten/Consolidate targets (preserve frontmatter shape: `name`, `description`, `metadata.type`; keep `feedback`/`project` bodies with **Why:** / **How to apply:**).
   - Delete retired/merged files.
   - Convert any relative dates ("yesterday", "last week") to absolute.
   - Rebuild `MEMORY.md`: one `- [Title](file.md) — hook` line per surviving file, no bodies, ordered most-load-bearing first. Remove index lines for deleted files; add lines for any file missing one.
   - Fix dangling `[[links]]` that pointed at deleted files (repoint to the merge target or drop).

5. **Report.** Summarize: kept N, shortened N, consolidated N→M, retired N (with the ground-truth reason for each retire). In interactive mode, confirm each delete/merge before writing.

## Guardrails
- One fact per file; MEMORY.md is an index only — never put memory bodies in it.
- Don't invent or "improve" facts — consolidation reorganizes existing, verified content; it does not add claims.
- Don't touch a different config's store. Only the active session's memory dir.
- If the store is already lean (no duplicates, nothing stale, nothing bloated), say so and change nothing — don't churn for its own sake.
