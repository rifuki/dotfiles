#!/bin/bash
set -e

# ========== OS Check ==========
if [[ "$(uname)" != "Darwin" ]]; then
  echo "❌ This script is for macOS only. Detected non-macOS system — aborting!"
  exit 1
fi

# ========== Confirm Helper ==========
confirm() {
  local _ans
  if [ -t 0 ] || [ -c /dev/tty ]; then
    printf "%s [y/n]: " "$1"
    read -r _ans < /dev/tty
    case "${_ans}" in
      [yY]|[yY][eE][sS]) return 0 ;;
      *) return 1 ;;
    esac
  fi
  return 1
}

cat << 'EOF'
================================================
  Homebrew clean uninstaller — macOS
================================================
This script will completely remove:
  • All Homebrew packages (formulae & casks)
  • Homebrew itself (via official uninstall script)
  • All residual files, caches, and logs
================================================
EOF

if ! command -v brew &>/dev/null; then
  echo "✅ Homebrew is not installed. Nothing to do."
  exit 0
fi

if ! confirm "Proceed with complete Homebrew removal?"; then
  echo "⏭️  Cancelled."
  exit 0
fi

echo ""

# ========== Remove All Cask Apps ==========
# Cask apps are actual .app files in /Applications, not removed by official script
echo "==> Removing all Homebrew cask apps..."
_casks="$(brew list --cask 2>/dev/null)" || true
if [ -n "$_casks" ]; then
  echo "$_casks" | xargs brew uninstall --cask --force 2>/dev/null || true
  echo "✅ Cask apps removed"
else
  echo "✅ No cask apps found"
fi

# ========== Remove All Formulae ==========
echo "==> Removing all Homebrew formulae..."
_formulae="$(brew list --formula 2>/dev/null)" || true
if [ -n "$_formulae" ]; then
  echo "$_formulae" | xargs brew uninstall --formula --force --ignore-dependencies 2>/dev/null || true
  echo "✅ Formulae removed"
else
  echo "✅ No formulae found"
fi

# ========== Uninstall Homebrew (official script) ==========
# Official script handles: taps, remaining files, and Homebrew core
echo "==> Running official Homebrew uninstall script..."
set +e
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)" -- --force
set -e
echo "✅ Homebrew uninstalled"

# ========== Clean Residual Files ==========
echo "==> Cleaning up residual files..."

# Homebrew directories (Apple Silicon + Intel)
sudo rm -rf /opt/homebrew 2>/dev/null || true
sudo rm -rf /usr/local/Homebrew 2>/dev/null || true
sudo rm -rf /usr/local/Caskroom 2>/dev/null || true
sudo rm -rf /usr/local/Cellar 2>/dev/null || true
sudo rm -rf /usr/local/bin/brew 2>/dev/null || true

# Caches and logs
rm -rf "$HOME/.cache/Homebrew" 2>/dev/null || true
rm -rf "$HOME/Library/Caches/Homebrew" 2>/dev/null || true
rm -rf "$HOME/Library/Logs/Homebrew" 2>/dev/null || true

echo "✅ Residual files removed"

# ========== Done ==========
echo ""
echo "✅ Homebrew completely removed — no residue!"
echo "👉 Restart your terminal to apply changes"
