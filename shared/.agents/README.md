# Shared agent skills

One source of truth for skills shared across agents. `~/.agents` symlinks to this
directory, `~/.claude/skills/<name>` links per skill to `../../.agents/skills/<name>`
(macos/install.sh creates and repairs the links), and OpenCode discovers
`~/.agents/skills` and `~/.claude/skills` on its own. Nothing here is copied or
synced; a skill exists in exactly one place.

## Adding a skill

The Skills CLI writes through the `~/.agents` symlink straight into this repo:

```sh
npx skills find <query>     # browse, then:
npx skills add <package>    # installs into skills/ and updates .skill-lock.json
git add -A shared/.agents && git commit
```

By hand, for a skill from anywhere else:

1. `skills/<skill-id>/SKILL.md` with frontmatter `name` and `description`. The
   description decides when an agent picks the skill up, so say what it is for
   and when to use it, in plain words; a skill without one is never advertised.
   IDs are lowercase kebab-case. Supporting files go in `scripts/` and
   `references/` beside `SKILL.md`; paths written inside a skill are relative to
   its own directory.
2. Add the upstream `LICENSE` and a `SOURCE` line, like the antislop
   directories carry: `<project> <version> @ <commit> (<license>, <repo>)`.
3. Commit. OpenCode sees the skill at its next step, no restart. Claude Code
   needs one link, or a run of the skills part of macos/install.sh:

   ```sh
   ln -s ../../.agents/skills/<skill-id> ~/.claude/skills/<skill-id>
   ```

## What belongs here

Third-party and publishable skills only. This repo is public; anything
personal or internal (the ce-* and wiki-* ecosystems, vault tooling) stays
outside it. Personal skills in `~/.claude/skills` are still visible to every
agent through the compatibility sources, so "not in this repo" does not mean
"not shared".

## Rules of the road

- A markdown file at the `skills/` root is itself discovered as a skill. Keep
  documentation in this file, one level above.
- `metadata.opencode/autoinvoke: false` hides a skill from automatic discovery
  but keeps it loadable by its exact ID; skill permissions can be scoped with
  `skill` action rules in opencode.jsonc.
- Update a skill by rerunning `npx skills add` over it (it refreshes content
  and lock hash), or by editing in place and updating the `SOURCE` line.
- Removing a skill means deleting the directory here, the lock entry, and the
  `~/.claude/skills/<name>` link, then committing.
