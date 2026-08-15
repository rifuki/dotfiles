#!/usr/bin/env bash
# Register every compound-engineering plugin skill as a personal skill.
#
# Why: the plugin is installed + enabled under $CLAUDE_CONFIG_DIR, but its
# skills are not picked up by the skill loader. Personal skills in
# ~/.claude-monklabs/skills/ are, and the loader follows symlinks (solana-dev
# already relies on that). So we link the plugin's skills in.
#
# Re-run after a plugin update (the version dir changes); it re-points the
# single .ce-current pointer, adds new skills, and prunes removed ones.

set -euo pipefail

config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
skills_dir="$config_dir/skills"
plugin_dir="$config_dir/plugins/cache/compound-engineering-plugin/compound-engineering"

if [ ! -d "$plugin_dir" ]; then
  echo "compound-engineering plugin not found at $plugin_dir" >&2
  exit 1
fi

# newest installed version (highest semver-ish dir name)
version="$(ls -1 "$plugin_dir" | sort -V | tail -1)"
source_skills="$plugin_dir/$version/skills"

if [ ! -d "$source_skills" ]; then
  echo "no skills dir in $plugin_dir/$version" >&2
  exit 1
fi

mkdir -p "$skills_dir"

# single version pointer, so a plugin upgrade only moves one link
ln -sfn "$plugin_dir/$version" "$skills_dir/.ce-current"

linked=0
for path in "$source_skills"/*/; do
  name="$(basename "$path")"
  [ -f "$path/SKILL.md" ] || continue
  ln -sfn ".ce-current/skills/$name" "$skills_dir/$name"
  linked=$((linked + 1))
done

# prune links whose target disappeared after an upgrade
pruned=0
for link in "$skills_dir"/*; do
  [ -L "$link" ] || continue
  case "$(readlink "$link")" in
    .ce-current/skills/*)
      if [ ! -e "$link" ]; then
        rm -f "$link"
        pruned=$((pruned + 1))
      fi
      ;;
  esac
done

echo "compound-engineering $version: linked $linked skills, pruned $pruned stale"
