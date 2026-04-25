# Auto-start Hyprland on the first TTY after login.
if [ -z "${WAYLAND_DISPLAY:-}" ] && [ "${XDG_VTNR:-}" = "1" ] && command -v Hyprland >/dev/null 2>&1; then
  exec Hyprland
fi
