---
title: "Hyprland refuses to start: XDG_RUNTIME_DIR is not set (missing /etc/machine-id)"
date: 2026-08-17
category: runtime-errors
module: gentoo-desktop
problem_type: runtime_error
component: tooling
symptoms:
  - "Hyprland aborts immediately with: CRIT: Critical error thrown: XDG_RUNTIME_DIR is not set!"
  - "loginctl list-sessions reports No sessions even while logged in"
  - "/run/user/<uid> is never created; the directory /run/user/ stays empty"
  - "journalctl shows pam_systemd(login:session): Failed to get user record: No such process"
  - "systemd-udevd logs Failed to resolve group 'disk'/'kvm'/'cuse' at boot"
root_cause: incomplete_setup
resolution_type: environment_setup
severity: critical
tags: [hyprland, systemd, machine-id, logind, xdg-runtime-dir, gentoo, wayland, pam]
---

# Hyprland refuses to start: XDG_RUNTIME_DIR is not set (missing /etc/machine-id)

## Problem

Hyprland aborts at launch with `XDG_RUNTIME_DIR is not set!` and the desktop is
completely unusable. The compositor is not at fault: `/etc/machine-id` was missing
from the system, which silently disabled systemd session creation for every login.

## Symptoms

- `Hyprland` dies instantly:
  ```
  CRIT ]: Critical error thrown: XDG_RUNTIME_DIR is not set!
  terminate called after throwing an instance of 'std::runtime_error'
    what():  XDG_RUNTIME_DIR is not set!
  ```
- `loginctl list-sessions` prints `No sessions.` even with an active TTY/SSH login.
- `ls /run/user/` is empty: the per-user runtime directory is never created.
- `journalctl -b -p err` shows, on both TTY and SSH logins:
  ```
  login[797]: pam_systemd(login:session): Failed to get user record: No such process
  sshd-session[4898]: pam_systemd(sshd:session): Failed to get user record: No such process
  ```
- Seemingly unrelated boot noise that is actually the same root cause:
  ```
  systemd-udevd: /usr/lib/udev/rules.d/50-udev-default.rules:101 Failed to resolve group 'disk', ignoring: Unknown group
  systemd-udevd: 60-tpm-udev.rules:3 Failed to resolve user 'tss', ignoring: Unknown user
  NetworkManager: <error> /etc/machine-id: no valid machine-id. Use fake one based on secret-key
  ```

## What Didn't Work

- **Chasing the udev "Unknown group" errors.** They suggest a corrupted `/etc/group`,
  but `getent group disk kvm cuse tss` resolved every one of them correctly. The
  failures were early-boot NSS lookups collapsing for a different reason.
- **Chasing `/etc/group` and `/etc/passwd` corruption.** Both files were intact
  (31 and 56 entries), and `getent passwd` worked.
- **Inspecting `systemd-userdbd` / `systemd-logind`.** Both were `active (running)`.
  Their health is not evidence that sessions can be created.
- **Reading `nsswitch.conf`.** It was correct (`passwd: files systemd`,
  `group: files [SUCCESS=merge] systemd`). The NSS *configuration* was never the issue.

The misleading part is that none of these surfaces mention `machine-id`. Only
NetworkManager names it directly, and its message reads like a cosmetic warning.

## Solution

Confirm the file is genuinely absent, then regenerate it as root:

```bash
ls -la /etc/machine-id          # No such file or directory
ls -la /run/machine-id          # also absent, no transient fallback in place

sudo systemd-machine-id-setup   # "Initializing machine ID from random generator."
sudo systemctl restart systemd-logind
```

Verify from a **fresh** login (the existing session cannot retroactively gain one):

```bash
echo "$XDG_RUNTIME_DIR"          # /run/user/1000
loginctl list-sessions           # sessions now listed
ls -ld /run/user/1000            # drwx------ ... rifuki rifuki
```

`/var/lib/dbus/machine-id` is a symlink to `/etc/machine-id` on this system, so it
is repaired by the same step; no separate `dbus-uuidgen` needed. Check with
`readlink -f /var/lib/dbus/machine-id` before assuming this holds elsewhere.

## Why This Works

The failure is a single chain, and every symptom above is one link in it:

```
/etc/machine-id missing
  └─> systemd-logind cannot identify the machine, so PAM session registration fails
        └─> pam_systemd: "Failed to get user record: No such process"
              └─> no logind session is created for the login
                    └─> /run/user/<uid> is never created
                          └─> XDG_RUNTIME_DIR is unset in the user environment
                                └─> Hyprland aborts: it requires XDG_RUNTIME_DIR
                                    for its Wayland socket and instance directory
```

The udev "Unknown group" errors belong to the same chain: `nsswitch.conf` routes
`group` through the `systemd` NSS module, which cannot answer while systemd's
machine identity is unresolved, so early-boot lookups fail even though `/etc/group`
is perfectly fine. Once `machine-id` exists, they stop.

`XDG_RUNTIME_DIR` is not something a compositor can synthesize; it must be a
logind-owned, correctly-permissioned directory. Hyprland is right to refuse.

## Prevention

- **Read the chain from the bottom, not the top.** `XDG_RUNTIME_DIR is not set` is
  never a compositor bug. Walk backwards: runtime dir → session → PAM → logind →
  machine identity. The lowest link is the real defect.
- **Treat `loginctl list-sessions` returning `No sessions` as the decisive signal.**
  It is far more diagnostic than the compositor's error, and it takes one command.
- **Add `/etc/machine-id` to any post-install or system-restore checklist.** It is a
  single 33-byte file that no package owns and no integrity check flags, yet its
  absence disables graphical login entirely.
- **Do not trust "service is active" as proof of function.** `systemd-logind` and
  `systemd-userdbd` both reported `active (running)` throughout the outage.
- **Quick triage one-liner:**
  ```bash
  test -s /etc/machine-id || echo "MISSING /etc/machine-id: regenerate with systemd-machine-id-setup"
  ```

## Related Issues

- Hyprland requires `XDG_RUNTIME_DIR` before backend creation; see the compositor's
  startup order in its `Crashes and Bugs` wiki page: <https://wiki.hypr.land/Crashes-and-Bugs/>
- Machine identity is also consumed by D-Bus (`/var/lib/dbus/machine-id`) and
  NetworkManager, which is why the same root cause produces log noise across
  unrelated daemons.
