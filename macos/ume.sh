#!/usr/bin/env bash
# Builds and installs ume, the tiling window manager, from source.
#
#   UME_SRC       the ume checkout, cloned there when missing (default ~/.local/src/ume)
#   UME_REPO      where to clone it from
#   UME_IDENTITY  code-signing identity, created when missing (default ume-cert)
#
# An existing checkout is built as it is, never pulled.
set -euo pipefail

SRC=${UME_SRC:-$HOME/.local/src/ume}
REPO=${UME_REPO:-git@github.com:rifuki/ume.git}
IDENTITY=${UME_IDENTITY:-ume-cert}
AGENT=$HOME/Library/LaunchAgents/dev.ume.daemon.plist

say() { printf '  ume: %s\n' "$1"; }

have_identity() {
  security find-identity -p codesigning | grep -q "\"$IDENTITY\""
}

# macOS ties the Accessibility and Screen Recording grants to the signature. An ad hoc one
# changes with every build and loses them, so ume is signed with one self-signed identity.
make_identity() {
  local tmp pass
  tmp=$(mktemp -d)
  # shellcheck disable=SC2064
  trap "/bin/rm -rf '$tmp'" EXIT
  cat >"$tmp/cert.conf" <<EOF
[req]
distinguished_name = dn
x509_extensions = ext
prompt = no
[dn]
CN = $IDENTITY
[ext]
basicConstraints = critical,CA:false
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
EOF
  # The system openssl: its PKCS#12 files are the kind the keychain reads.
  /usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -config "$tmp/cert.conf" \
    -keyout "$tmp/key.pem" -out "$tmp/cert.pem" 2>/dev/null
  pass=$(/usr/bin/openssl rand -hex 16)
  /usr/bin/openssl pkcs12 -export -inkey "$tmp/key.pem" -in "$tmp/cert.pem" \
    -name "$IDENTITY" -out "$tmp/identity.p12" -passout "pass:$pass"
  security import "$tmp/identity.p12" -k "$HOME/Library/Keychains/login.keychain-db" \
    -P "$pass" -T /usr/bin/codesign >/dev/null
  say "created the signing identity $IDENTITY in the login keychain"
}

if ! command -v cargo >/dev/null && [ -f "$HOME/.cargo/env" ]; then
  # shellcheck disable=SC1091
  . "$HOME/.cargo/env"
fi
command -v cargo >/dev/null || { say "cargo not found; install Rust first"; exit 1; }

if [ ! -d "$SRC/.git" ]; then
  say "cloning $REPO into $SRC"
  mkdir -p "$(dirname "$SRC")"
  git clone "$REPO" "$SRC"
fi

have_identity || make_identity

say "building and installing from $SRC, signed by $IDENTITY"
(cd "$SRC" && cargo xtask install --identity "$IDENTITY")

if [ ! -f "$AGENT" ]; then
  "$HOME/.local/bin/ume" service install --manage
  say "started the LaunchAgent"
fi

cat <<EOF

  ume is installed. In System Settings > Privacy & Security, allow ume under
    - Accessibility                      (moving windows)
    - Screen & System Audio Recording    (ume notch)
  After a change of signing identity, remove ume from both lists and add it again.
EOF
