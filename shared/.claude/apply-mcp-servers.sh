#!/usr/bin/env bash
# Merge mcp-servers.json into every Claude profile's ~/.claude.json.
#
# User-scope MCP config lives in .claude.json, which link-profiles.sh deliberately
# never shares — it also holds oauthAccount, and Claude Code rewrites the whole file
# constantly, so a symlink would let the last writer clobber every other account's
# identity. That leaves each profile needing its own copy of the same server list.
#
# Merge semantics: servers named here are added or updated. Anything already in a
# profile and not named here is left alone, so a machine-local server you added by
# hand survives. Nothing is ever deleted.
#
#   ./apply-mcp-servers.sh          # apply to ~/.claude and every ~/.claude-*/
#   ./apply-mcp-servers.sh --check  # report only

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$HERE/mcp-servers.json"
[ -f "$SRC" ] || { echo "missing $SRC" >&2; exit 1; }

mode=apply
[ "${1-}" = "--check" ] && mode=check

targets=("$HOME/.claude")
for d in "$HOME"/.claude-*/; do
  [ -d "$d" ] || continue
  # A real profile has its own config file; this skips backup dirs.
  [ -f "${d}.claude.json" ] || [ -f "$HOME/$(basename "$d").json" ] && targets+=("${d%/}")
done

rc=0
for t in "${targets[@]}"; do
  name="~${t#$HOME}"
  cfg="$t/.claude.json"
  [ "$t" = "$HOME/.claude" ] && cfg="$HOME/.claude.json"
  if [ ! -f "$cfg" ]; then
    echo "  $name: no .claude.json yet — skipped (log in first)"
    continue
  fi
  out="$(SRC="$SRC" CFG="$cfg" MODE="$mode" python3 - <<'PY'
import json, os, sys

src = json.load(open(os.environ["SRC"]))["mcpServers"]
cfg_path = os.environ["CFG"]
cfg = json.load(open(cfg_path))
cur = cfg.get("mcpServers", {})

add = [k for k in src if k not in cur]
upd = [k for k in src if k in cur and cur[k] != src[k]]

if os.environ["MODE"] == "check":
    print("DRIFT " + ",".join(add + upd) if (add or upd) else "OK")
    sys.exit(1 if (add or upd) else 0)

if add or upd:
    cur.update(src)
    cfg["mcpServers"] = cur
    tmp = cfg_path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(cfg, f, indent=2)
    os.replace(tmp, cfg_path)
    print("added=%s updated=%s total=%d" % (",".join(add) or "-", ",".join(upd) or "-", len(cur)))
else:
    print("already in sync (%d servers)" % len(cur))
PY
)" || rc=1
  echo "  $name: $out"
done

exit $rc
