# Cursor Themes on Hyprland

How the Miku cursor setup works, and how to replace it with any other xcursor theme.

---

## How the Current Setup Works

Two cursor themes are installed and serve different roles:

| Theme | Format | Used by |
|---|---|---|
| `miku-cursor-linux` | xcursor | GTK apps (Ghostty, nwg-look, etc.) |
| `theme_miku-cursor` | hyprcursor | Wayland compositor (Hyprland itself, Chrome, Kitty, etc.) |

### Why two themes?

Hyprland's compositor cursor (what you see when moving over most apps) comes from the **hyprcursor** theme. Apps that use the `cursor-shape-v1` Wayland protocol let the compositor draw the cursor entirely — they never touch cursor images themselves.

GTK apps (notably Ghostty) load cursor images **client-side** directly from the xcursor theme via `XCURSOR_THEME`. They draw their own cursor surface over Wayland, which is why Ghostty always had correct colors even when the compositor cursor was wrong.

`hyprland.conf` sets both:

```ini
exec-once = hyprctl setcursor theme_miku-cursor 24
env = XCURSOR_THEME,miku-cursor-linux
env = XCURSOR_SIZE,24
env = HYPRCURSOR_THEME,theme_miku-cursor
env = HYPRCURSOR_SIZE,24
```

GSettings also needs to be set for GTK apps that read from dconf (takes priority over `settings.ini`):

```bash
gsettings set org.gnome.desktop.interface cursor-theme 'miku-cursor-linux'
gsettings set org.gnome.desktop.interface cursor-size 24
```

---

## Backup and Restore

Both halves of the setup are committed, so the cursor survives a wiped machine even if
upstream disappears:

| What | Where in repo | Size |
|---|---|---|
| `theme_miku-cursor` (animated hyprcursor, 66 cursors + 65 aliases) | `linux/shared/.local/share/icons/theme_miku-cursor/` | 1.6 MB |
| `miku-cursor-linux` (xcursor source, pinned **1.2.6**) | `linux/shared/assets/miku-cursor-linux-1.2.6.tar.xz` | 53 KB |
| Generator | `linux/shared/.local/bin/build-miku-hyprcursor` | — |

The archive is 53 KB because xcursor stores **uncompressed raw ARGB** bitmaps — 18 MB extracted
compresses ~340×.

`install.sh` extracts the vendored archive first and only falls back to a download. The version is
**pinned to 1.2.6, not `latest`**: a future upstream release could ship different cursor art and
silently change the cursor on a reinstall.

`sha256` of the vendored archive:

```
6a13eec3928937575bc35435410f276410c899245d0ca98c7f9e1cc23f1f2689
```

### Restoring by hand

```bash
tar -xf ~/.dotfiles/linux/shared/assets/miku-cursor-linux-1.2.6.tar.xz \
  -C ~/.local/share/icons/
python3 ~/.local/bin/build-miku-hyprcursor    # rebuilds theme_miku-cursor, needs Pillow
hyprctl setcursor theme_miku-cursor 24
```

`build-miku-hyprcursor` wipes and regenerates `~/.local/share/icons/theme_miku-cursor/hyprcursors/`.
When `install.sh` has symlinked the repo copies in there, the wipe removes only those symlinks —
the files in the repo are never touched.

### Re-syncing the backup after a rebuild

```bash
rsync -a --delete ~/.local/share/icons/theme_miku-cursor/ \
  ~/.dotfiles/linux/shared/.local/share/icons/theme_miku-cursor/
```

`.hlc` files are zip archives and `zipfile` stamps the build time into each entry, so rebuilt
files are never byte-identical to the committed ones even when the cursors are the same. Compare
the *contents* (`meta.hl` + PNGs), not the raw bytes, before assuming something drifted.

---

## How `theme_miku-cursor` Was Created

The hyprcursor theme was generated from `miku-cursor-linux` using a Python script that parses xcursor binary files directly. This was necessary because `xcur2png` (the standard tool) swaps the R and B channels, producing blue cursors instead of teal/cyan.

> **The live theme is animated.** The generator that actually produces it is tracked at
> `linux/shared/.local/bin/build-miku-hyprcursor` (installed to `~/.local/bin/`). It keeps every
> animation frame — 32 frames per cursor at 116 ms (`default`, `wait`) and 83 ms (`progress`) —
> and recreates the 65 legacy-name alias symlinks. The standalone script further down this page
> is the simpler *static* variant, kept as a reference for converting other themes.
> Run the real one with `python3 ~/.local/bin/build-miku-hyprcursor` (needs Pillow).

### The xcur2png Channel Swap Bug

`xcur2png` outputs BGRA bytes read as RGBA PNG — red and blue are swapped. The correct approach is to parse xcursor binary files directly with Python.

### Xcursor Binary Format

```
Header:  magic(4) + header_size(4) + version(4) + ntoc(4)
TOC:     ntoc × [type(4) + subtype(4) + position(4)]

Image chunk at position:
  9 × uint32 LE: hsize, type, subtype, VERSION, width, height, xhot, yhot, delay
  then width×height pixels as 32-bit ARGB (premultiplied alpha, little-endian)
  pixel bits: (A<<24)|(R<<16)|(G<<8)|B
```

The version field (4th uint32 in the image header) is easy to miss — omitting it shifts all subsequent fields and produces wrong dimensions (e.g. 1×32 instead of 32×32).

Pixels are **premultiplied alpha** — un-premultiply before saving PNG:

```python
if a > 0:
    r = min(255, r * 255 // a)
    g = min(255, g * 255 // a)
    b = min(255, b * 255 // a)
```

### Hyprcursor Theme Format

A hyprcursor theme lives in `~/.local/share/icons/<theme_name>/` with this structure:

```
manifest.hl
hyprcursors/
  arrow.hlc
  text.hlc
  ...
```

`manifest.hl` (Hyprland config format):

```
name = My Cursor Theme
cursors_directory = hyprcursors
```

Each `.hlc` is a **zip archive** containing:
- `meta.hl` — metadata for this cursor shape
- `<name>_<size>.png` — one PNG per size

`meta.hl` format:

```
resize_algorithm = bilinear
hotspot_x = 4
hotspot_y = 4
define_size = 32, arrow_32.png, 0
define_size = 48, arrow_48.png, 0
define_size = 64, arrow_64.png, 0
```

The third field in `define_size` is the frame delay in milliseconds. `0` means static (one frame); a non-zero delay with multiple `define_size` lines for the same size makes the cursor animated. The Miku theme uses animation (see the v0.49.0 crash note below — it does not apply to current Hyprland).

`resize_algorithm` **must be** `bilinear`. See crash section below.

---

## Converting Any xcursor Theme to Hyprcursor

Use this Python script. Replace `INPUT_DIR` and `OUTPUT_DIR` with your paths.

```python
#!/usr/bin/env python3
"""Convert xcursor theme to hyprcursor (.hlc) format."""
import re, struct, zipfile
from pathlib import Path
from PIL import Image

INPUT_DIR  = Path.home() / ".local/share/icons/my-cursor-linux/cursors"
OUTPUT_DIR = Path.home() / ".local/share/icons/theme_my-cursor"
SIZES      = [32, 48, 64, 96]

CHUNK_IMAGE = 0xFFFD0002

def read_xcursor(path):
    data = Path(path).read_bytes()
    if data[:4] != b"Xcur":
        return []
    _, _, ntoc = struct.unpack_from("<III", data, 4)
    toc = [struct.unpack_from("<III", data, 16 + i * 12) for i in range(ntoc)]
    images = []
    for ctype, size, pos in toc:
        if ctype != CHUNK_IMAGE:
            continue
        # 9 fields: hsize, type, subtype, VERSION, w, h, xhot, yhot, delay
        hsize, _, _, version, w, h, xhot, yhot, delay = struct.unpack_from("<IIIIIIIII", data, pos)
        n = w * h
        px_off = pos + hsize
        pixels = struct.unpack_from(f"<{n}I", data, px_off)
        rgba = bytearray(n * 4)
        for j, p in enumerate(pixels):
            a = (p >> 24) & 0xFF
            r = (p >> 16) & 0xFF
            g = (p >>  8) & 0xFF
            b =  p        & 0xFF
            if a > 0:  # un-premultiply
                r = min(255, r * 255 // a)
                g = min(255, g * 255 // a)
                b = min(255, b * 255 // a)
            rgba[j*4:j*4+4] = bytes([r, g, b, a])
        images.append((size, w, h, xhot, yhot, delay, rgba))
    return images

def make_hlc(cursor_path, out_path):
    images = read_xcursor(cursor_path)
    if not images:
        return False

    # Pick one image per target size (closest match)
    by_size = {}
    for size, w, h, xhot, yhot, delay, rgba in images:
        for target in SIZES:
            if target not in by_size or abs(w - target) < abs(by_size[target][1] - target):
                by_size[target] = (size, w, h, xhot, yhot, delay, rgba)

    name = cursor_path.stem
    meta_lines = ["resize_algorithm = bilinear"]
    png_files = {}

    for target in SIZES:
        if target not in by_size:
            continue
        size, w, h, xhot, yhot, delay, rgba = by_size[target]
        img = Image.frombytes("RGBA", (w, h), bytes(rgba))
        if w != target:
            img = img.resize((target, target), Image.LANCZOS)
            scale = target / w
            xhot = round(xhot * scale)
            yhot = round(yhot * scale)
        if not meta_lines[1:]:  # first size sets hotspot
            meta_lines.append(f"hotspot_x = {xhot}")
            meta_lines.append(f"hotspot_y = {yhot}")
        png_name = f"{name}_{target}.png"
        png_files[png_name] = img
        meta_lines.append(f"define_size = {target}, {png_name}, 0")

    if len(meta_lines) <= 1:
        return False

    out_path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(out_path, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("meta.hl", "\n".join(meta_lines) + "\n")
        for png_name, img in png_files.items():
            import io
            buf = io.BytesIO()
            img.save(buf, "PNG")
            zf.writestr(png_name, buf.getvalue())
    return True

# Write manifest
hyprcursors_dir = OUTPUT_DIR / "hyprcursors"
hyprcursors_dir.mkdir(parents=True, exist_ok=True)
(OUTPUT_DIR / "manifest.hl").write_text("name = My Cursor\ncursors_directory = hyprcursors\n")

# Skip names with special characters (invalid in hyprcursor)
valid_name = re.compile(r'^[A-Za-z0-9_\-\.]+$')

for cursor_file in sorted(INPUT_DIR.iterdir()):
    if cursor_file.is_symlink() or not cursor_file.is_file():
        continue
    if not valid_name.match(cursor_file.stem):
        print(f"skip (invalid name): {cursor_file.name}")
        continue
    out = hyprcursors_dir / f"{cursor_file.stem}.hlc"
    ok = make_hlc(cursor_file, out)
    print(f"{'ok' if ok else 'skip (not xcursor)'}: {cursor_file.name}")

print("Done.")
```

Run with: `python3 convert_cursor.py`

Requires `Pillow`: `pip install Pillow` or `sudo emerge dev-python/pillow`.

---

## Switching to a Different Cursor Theme

1. **Install the new xcursor theme** to `~/.local/share/icons/<new-theme>/`

2. **Generate the hyprcursor theme** using the script above with updated `INPUT_DIR`/`OUTPUT_DIR`

3. **Update `hyprland.conf`:**
   ```ini
   exec-once = hyprctl setcursor theme_<new-theme> 24
   env = XCURSOR_THEME,<new-theme>
   env = HYPRCURSOR_THEME,theme_<new-theme>
   ```

4. **Update GTK settings:**
   ```bash
   gsettings set org.gnome.desktop.interface cursor-theme '<new-theme>'
   # Also update ~/.config/gtk-3.0/settings.ini and ~/.config/gtk-4.0/settings.ini
   ```

5. **Reload Hyprland:** `hyprctl reload` or re-login

---

## Known Bugs and Workarounds

### Hyprland crash: `tickAnimatedCursor` → SIGSEGV

**Affects:** Hyprland v0.49.0 with fractional monitor scale (e.g. 1.333)

**Cause:** `CCursorBuffer(cairo_surface*)` receives a null surface when
`resize_algorithm = none` is used and the monitor scale is not 1.0.
Cairo cannot create a surface for fractional-scaled sizes with no resize.

**Fix (hyprcursor theme):** Set `resize_algorithm = bilinear` in every `meta.hl`.

**Fix (animated cursors) — historical, v0.49.0 only:** Back then the crash persisted with
animated cursors, so the theme was flattened to static (`delay = 0`, one frame per size)
to work around a secondary bug in `tickAnimatedCursor`.

**No longer needed.** Verified on **Hyprland 0.54.3** with fractional scale **1.33**: the fully
animated theme (32 frames per cursor) runs without crashing. Do not flatten the theme to static
on current Hyprland — you would lose the animation for nothing. Keep `resize_algorithm = bilinear`.

### xcur2png produces wrong colors (blue instead of teal)

`xcur2png` outputs BGRA pixels labeled as RGBA — red and blue channels are swapped.
Use the Python script above instead, which parses the xcursor binary directly.

### Compositor cursor stays as default after changing `XCURSOR_THEME`

`XCURSOR_THEME` / xcursor fallback does **not** update the KMS hardware cursor in
Hyprland. Only `HYPRCURSOR_THEME` (native hyprcursor format) updates the compositor
cursor. You must have both themes set.

### GTK cursor ignores `settings.ini`

GTK apps prefer dconf/GSettings over `~/.config/gtk-3.0/settings.ini`.
Run: `gsettings set org.gnome.desktop.interface cursor-theme '<theme>'`

### hyprpaper orphaned after Hyprland crash/restart

hyprpaper binds to the session socket at `/run/user/<uid>/hypr/<sig>/.hyprpaper.sock`.
After a crash, old hyprpaper processes hold a stale socket path.
The `wallpaper-daemon` script detects this and kills the orphaned process before
starting a new one.

### Stale `HYPRLAND_INSTANCE_SIGNATURE` in open terminals

After a Hyprland crash and restart, terminals that were open before the crash
still export the old signature. `hyprctl` commands will fail with socket errors.

Fix: `export HYPRLAND_INSTANCE_SIGNATURE=$(ls -t /run/user/1000/hypr/ | head -1)`
