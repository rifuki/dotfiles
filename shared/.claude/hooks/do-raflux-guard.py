#!/usr/bin/env python3
"""PreToolUse guard: only raflux resources may be touched on DigitalOcean.

The doctl token on this machine belongs to the Monklabs *team* account, so a
single tool call can reach 17 droplets, 6 apps and 6 managed databases that have
nothing to do with raflux. This hook denies any DO call -- via the digitalocean
MCP server or via `doctl` / the DO API in Bash -- that names a non-raflux
resource.

Classification is by live inventory, cached briefly, with a baked-in fallback so
the guard still works offline. A resource counts as raflux when its name matches
RAFLUX_RE; everything else in the account is denied by name and by id.
"""

import json
import os
import re
import sys
import time
import urllib.error
import urllib.request

CACHE = os.path.expanduser("~/.claude/hooks/.do-inventory-cache.json")
CACHE_TTL = 600
DOCTL_CFG = os.path.expanduser("~/Library/Application Support/doctl/config.yaml")

RAFLUX_RE = re.compile(r"raflux|^monk-int$", re.I)

# Fallback inventory, captured 2026-08-08. Used when the API is unreachable.
# Refresh with: doctl compute droplet list / doctl apps list / doctl databases list
FALLBACK_DENY = {
    "470931010": "MONK", "470931247": "Techtonix", "472881730": "DOA-1",
    "482154058": "Tokenease", "482823524": "DOA-2-Secret", "487199678": "Cheatcode",
    "487268624": "OMI", "496432261": "DOA-3", "506738817": "Hikari-2",
    "510939109": "NowWeKnow", "524412878": "Dining-Hub", "537354721": "Wagmi",
    "538018173": "DOA-4", "549511505": "Moltbot", "568571953": "Easypad-2",
    "92e37f16-2aa8-4ba0-a085-e53dfaed8229": "icbs",
    "57ed0876-c2af-4273-b2f4-4a90de6b0fd7": "clippo",
    "16dc6b60-95ca-41a8-ac98-f586879a85fa": "simple-proxy-2",
    "df42701e-fe14-4914-8584-5ec99ffea9e6": "simple-proxy",
    "c730df27-32b6-452b-be15-861daf3c9584": "db-clippo",
    "cee85a67-51fe-4559-96f3-0767aa9129f4": "db-icbs",
    "7143b9e0-e05a-476a-98bc-0aa8b685238b": "db-valkey-clippo",
}


def token():
    try:
        with open(DOCTL_CFG) as fh:
            for line in fh:
                if line.startswith("access-token:"):
                    return line.split(":", 1)[1].strip()
    except OSError:
        pass
    return os.environ.get("DIGITALOCEAN_API_TOKEN", "")


def fetch(path, tok):
    req = urllib.request.Request(
        "https://api.digitalocean.com/v2/" + path,
        headers={"Authorization": "Bearer " + tok},
    )
    with urllib.request.urlopen(req, timeout=5) as resp:
        return json.load(resp)


def live_inventory():
    """Map of {identifier -> display name} for every NON-raflux resource."""
    tok = token()
    if not tok:
        return None
    deny = {}
    try:
        for d in fetch("droplets?per_page=200", tok).get("droplets", []):
            if not RAFLUX_RE.search(d.get("name", "")):
                deny[str(d["id"])] = d.get("name", "")
        for a in fetch("apps?per_page=200", tok).get("apps", []):
            name = (a.get("spec") or {}).get("name", "")
            if not RAFLUX_RE.search(name):
                deny[str(a["id"])] = name
        for b in fetch("databases?per_page=200", tok).get("databases", []):
            if not RAFLUX_RE.search(b.get("name", "")):
                deny[str(b["id"])] = b.get("name", "")
    except (urllib.error.URLError, KeyError, ValueError, TimeoutError, OSError):
        return None
    return deny


def inventory():
    try:
        st = os.stat(CACHE)
        if time.time() - st.st_mtime < CACHE_TTL:
            with open(CACHE) as fh:
                return json.load(fh)
    except (OSError, ValueError):
        pass
    deny = live_inventory()
    if deny is None:
        return FALLBACK_DENY
    try:
        with open(CACHE, "w") as fh:
            json.dump(deny, fh)
    except OSError:
        pass
    return deny


def scalars(node, out):
    if isinstance(node, dict):
        for v in node.values():
            scalars(v, out)
    elif isinstance(node, (list, tuple)):
        for v in node:
            scalars(v, out)
    elif isinstance(node, (str, int, float)) and not isinstance(node, bool):
        out.append(str(node))


def offender(values, deny):
    """Return (identifier, name) of the first non-raflux resource referenced.

    Names match only on a whole value -- `MONK` is a substring of `monk-int`, so
    substring matching here would block the raflux box itself. Ids and uuids are
    unambiguous, so those match on a word boundary anywhere in the text.
    """
    names = {n.lower(): (i, n) for i, n in deny.items() if n}
    for raw in values:
        v = raw.strip().strip("\"'")
        if v.lower() in names:
            return names[v.lower()]
        for word in re.split(r"[\s,=&/?]+", v):
            w = word.strip().strip("\"'")
            if w.lower() in names:
                return names[w.lower()]
    blob = "\n".join(values)
    for ident, name in deny.items():
        if re.search(r"(?<![\w-])" + re.escape(ident) + r"(?![\w-])", blob):
            return (ident, name)
    return None


def deny_response(ident, name, tool):
    reason = (
        f"Blocked by the raflux-only DigitalOcean rule: this call references "
        f"'{name}' ({ident}), which is a Monklabs resource unrelated to raflux. "
        f"Only resources matching /raflux/i plus the droplet monk-int may be "
        f"touched. Tool: {tool}. If this is genuinely intended, the user must "
        f"edit ~/.claude/hooks/do-raflux-guard.py -- do not work around it."
    )
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }))
    sys.exit(0)


def main():
    try:
        payload = json.load(sys.stdin)
    except (ValueError, OSError):
        sys.exit(0)

    tool = payload.get("tool_name", "")
    tool_input = payload.get("tool_input", {}) or {}

    if tool.startswith("mcp__digitalocean__"):
        values = []
        scalars(tool_input, values)
    elif tool in ("Bash", "BashOutput"):
        cmd = str(tool_input.get("command", ""))
        if not re.search(r"\bdoctl\b|api\.digitalocean\.com", cmd):
            sys.exit(0)
        values = [cmd]
    else:
        sys.exit(0)

    if not values:
        sys.exit(0)

    hit = offender(values, inventory())
    if hit:
        deny_response(hit[0], hit[1], tool)
    sys.exit(0)


if __name__ == "__main__":
    main()
