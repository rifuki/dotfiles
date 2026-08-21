# ── Sesi Wayland di TTY1 ──────────────────────────────────────────────────────
#
# Default sejak migrasi 2026-08-19: niri.
# Untuk balik ke Hyprland tanpa mengedit file ini, set WM sebelum login:
#
#     WM=hyprland   → Hyprland (lewat start-hyprland)
#     WM=niri       → niri     (default)
#     WM=none       → tidak meluncurkan apa pun, tinggal di shell
#
# Hyprland dipanggil lewat start-hyprland, bukan binari Hyprland langsung.
# Hyprland >=0.56 memunculkan "WARNING: Hyprland is being launched without
# start-hyprland. This is highly advised against." karena start-hyprland adalah
# proses watchdog yang mengawasi compositor dan menyiapkan sesinya dengan benar.
#
# niri dipanggil lewat niri-session, bukan `niri` langsung: niri-session yang
# menjalankannya sebagai service systemd sehingga xdg-desktop-portal dan
# kawan-kawannya terikat ke graphical-session.target.
#
# Guard-nya tidak berubah, supaya compositor yang rusak tidak mengunci mesin:
#   - tty1 saja, jadi tty2..tty6 tetap shell polos
#   - dilewati kalau sudah ada sesi Wayland atau X
#   - tanpa `exec`, jadi begitu compositor keluar kamu mendarat kembali di
#     shell ini, bukan langsung ter-logout
#
# Untuk menonaktifkan, komentari blok di bawah atau unlink ~/.zprofile.
if [[ -z $WAYLAND_DISPLAY && -z $DISPLAY && $XDG_VTNR == 1 ]]; then
  case ${WM:-niri} in
    hyprland) start-hyprland ;;
    niri)     niri-session ;;
    none)     ;;
    *)        print -u2 "zprofile: WM='$WM' tidak dikenal; pilihannya niri|hyprland|none" ;;
  esac
fi
