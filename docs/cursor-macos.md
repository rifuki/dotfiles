# Cursor Theme on macOS

How the Miku cursor runs on macOS, and how to rebuild or replace it.

Companion to [`cursor-hyprland.md`](cursor-hyprland.md) — same artwork, same pinned
xcursor source, different delivery mechanism.

---

## Why This Is Not Like Linux

macOS has no cursor theme system. The stock cursors are baked into system frameworks,
and the only supported customisation is **System Settings → Accessibility → Display →
Pointer**, which changes pointer size and outline/fill colour. There is no equivalent of
`XCURSOR_THEME`, and nothing reads `.cur`/`.ani`/xcursor files.

The one working route is [Mousecape](https://github.com/sdmj76/Mousecape-swiftUI), a
SwiftUI rewrite of the original Mousecape. It registers replacement cursors through a
private CoreGraphics API (`CGSRegisterCursorWithImages`). Two consequences follow:

- **No SIP change is needed.** Nothing is patched on disk.
- **Registration is per-session.** It does not survive a reboot, and fast user switch
  reverts it. Hence the LaunchAgent below.

Verified working on macOS 26.5.2 (Tahoe), Apple Silicon: 49 of 49 cursors applied.

---

## How the Current Setup Works

| Piece | Where |
|---|---|
| Mousecape.app (pinned `Swift_v1.1.4`) | `/Applications/Mousecape.app` |
| Cape, committed pre-built | `macos/assets/miku-cursor.cape` → `~/Library/Application Support/Mousecape/capes/` |
| LaunchAgent | `macos/assets/com.rifuki.mousecape-miku.plist` → `~/Library/LaunchAgents/` |
| Generator | `macos/.local/bin/build-miku-cape` → symlinked into `~/.local/bin/` |
| xcursor source (pinned 1.2.6) | `linux/shared/assets/miku-cursor-linux-1.2.6.tar.xz` |

`install.sh` offers this as menu item **Miku Cursor**. The release zip is pinned by
sha256 — that build is adhoc-signed with no Team ID, so the checksum is the only thing
vouching for it.

The xcursor archive is deliberately **not** duplicated under `macos/`. Both platforms
build from the same 53 KB vendored tarball; only the output format differs.

### The LaunchAgent

```
mousecloak apply <cape>   # once at login
exec mousecloak listen    # stays resident, re-applies on fast user switch
```

`$HOME` is expanded by `/bin/sh` at run time rather than by launchd, so the plist is
portable and needs no path substitution at install time.

Check it:

```bash
launchctl print gui/$(id -u)/com.rifuki.mousecape-miku | grep -E 'state|pid'
tail /tmp/mousecape-miku.log
```

---

## Rebuilding the Cape

Only needed if the pinned `miku-cursor-linux` archive changes. Requires Pillow.

```bash
python3 ~/.dotfiles/macos/.local/bin/build-miku-cape \
  -o ~/.dotfiles/macos/assets/miku-cursor.cape
```

With no directory argument it extracts the vendored tarball to a temp dir and builds
from that, so nothing has to be installed under `~/.local/share/icons` first. The build
is reproducible — same archive in, byte-identical cape out.

Then re-apply:

```bash
cp ~/.dotfiles/macos/assets/miku-cursor.cape \
   ~/Library/Application\ Support/Mousecape/capes/
launchctl kickstart -k gui/$(id -u)/com.rifuki.mousecape-miku
```

> **Note:** macOS ships Python 3.9 with the Command Line Tools. The generator is written
> to that floor — no `tarfile` extraction filters, no 3.10+ syntax.

---

## The Cape Format

A `.cape` is an XML plist. Verified by decoding a `mousecloak dump` of macOS 26.5.2
rather than from documentation, which does not exist.

```
Author, CapeName, CapeVersion, Cloud, HiDPI, Identifier, MinimumVersion, Version
Cursors → {
  "com.apple.coregraphics.Arrow": {
      FrameCount, FrameDuration,          # duration in seconds, per frame
      HotSpotX, HotSpotY,                 # in points, not pixels
      PointsWide, PointsHigh,             # size of ONE frame
      Representations: [<PNG>, <PNG>, …]  # scale inferred from width / PointsWide
  }, …
}
```

Animated cursors are **one vertical strip per representation**, not a list of images:

```
image height == PointsHigh × FrameCount × scale
```

Pixel order is the same trap as on the Linux side: xcursor stores 32-bit ARGB
little-endian, so the bytes on disk are **B,G,R,A**. Reading them as RGBA swaps red and
blue and turns the teal cursor purple. `Image.frombytes(..., 'raw', 'BGRA')` handles it.

### Sizing: Why 32pt, and Why It Must Stay a Multiple of 32

The theme is **32×32 pixel art**. Its 48/64/96 "sizes" are not separate artwork — each
is a nearest-neighbour upscale of the same 32×32 master, and every frame has only two
alpha levels, so there is no antialiasing and no higher-resolution original to recover:

```
32 → 64  exact 2x    ✓
32 → 96  exact 3x    ✓
32 → 48  NOT exact   ✗   (1.5x — the source of the problem)
```

That makes the on-screen size a correctness question, not a taste one. A 2x display
renders a `POINTS`-sized cursor at `POINTS × 2` device pixels, and if that is not an
integer multiple of 32 the source pixels land on 1 or 2 screen pixels at random. The
artwork looks ragged, and no amount of resampling fixes it.

| `POINTS` | device px at 2x | ratio to master | result |
|---|---|---|---|
| 24 | 48 | 1.5x | ragged — the first version of this cape did this |
| **32** | **64** | **2x** | **every source pixel is a clean 2×2 block** |
| 16 | 32 | 1x | pixel-exact too, but a small cursor |

`build-miku-cape` therefore builds every representation from the 32 px master with
`Image.NEAREST` at integer scales only. Any smoothing filter turns hard-edged pixel art
to mush, and `LANCZOS` in particular looks worse than the problem it tries to solve.

Changing `POINTS` to a non-multiple of `MASTER_SIZE` brings the raggedness straight
back. Use 16 or 32, or change the size with `mousecloak scale` instead.

### Cursor Identifier Mapping

macOS names cursors `com.apple.coregraphics.Arrow`, `com.apple.cursor.13`, and so on.
The numbered ones are undocumented. The mapping in `build-miku-cape` was **not guessed**
— `mousecloak dump` was run against macOS 26.5.2, and every identifier was matched to an
xcursor name by looking at Apple's own artwork for it:

```bash
/Applications/Mousecape.app/Contents/MacOS/mousecloak dump system.cape
```

That is how `#11` is the closed hand and `#12` the open one, `#17`/`#18` are the left and
right window edges, and `#31`/`#32`/`#36` are vertical while `#27`/`#28`/`#38` are
horizontal. Redo this dump before porting any other theme — do not assume the numbering
is stable across macOS releases.

Three identifiers are intentionally unmapped: `com.apple.coregraphics.Empty` (invisible
by definition) and `com.apple.cursor.9`/`.10` (the screenshot camera, which has no
xcursor counterpart).

### Limits

Imposed by Mousecape, not by this repo:

- Maximum import size 512×512 px
- Maximum **24 frames** per animated cursor — miku peaks at 8, so nothing is dropped
- Apps that set their own cursors (Terminal, Excel) keep them. No safe workaround.

---

## Troubleshooting

**Cursor only changes near the Dock, reverts everywhere else.**
A non-default pointer colour makes macOS ignore custom cursors. Go to System Settings →
Accessibility → Display → Pointer and click **Reset Color**. `install.sh` warns when it
detects this.

**Cursor gone after reboot.**
Check the LaunchAgent is loaded (see above). Registration is per-session by design.

**Cursor looks ragged or grainy.**
Read the sizing section above — this is fractional scaling of pixel art, not a
resolution problem. Check `POINTS` is still a multiple of `MASTER_SIZE`.

**Wrong size.**
Prefer this over editing `POINTS`; the scale multiplier does not disturb the pixel grid
the way a non-integer `POINTS` does.

```bash
mousecloak scale 1.2    # no argument prints the current scale
```

---

## Porting a Different Theme

For an xcursor theme, point the generator at its `cursors/` directory:

```bash
python3 ~/.dotfiles/macos/.local/bin/build-miku-cape /path/to/theme/cursors \
  -o theme.cape -n "Theme Name"
```

`CURSOR_MAP` at the top of the script maps macOS identifiers to xcursor names, and most
themes use the same freedesktop names, so it usually needs no edits.

For a **Windows** `.cur`/`.ani` pack, skip this script — Mousecape imports those
directly, but only when the pack ships an `install.inf`. Without one there is no way to
tell which file is which cursor, and the maintainer has declined to work around it.
