#!/bin/zsh

# Loncatin kursor mouse ke tengah monitor yang lagi fokus.
# Dipanggil setelah pindah/fokus monitor (skhd) biar kursor ikut,
# tanpa perlu mouse_follows_focus global yang ganggu pas ganti window.

read -r cx cy <<< "$(yabai -m query --displays --display \
    | jq -r '.frame | "\(.x + .w/2 | floor) \(.y + .h/2 | floor)"')"

/opt/homebrew/bin/cliclick "m:${cx},${cy}"
