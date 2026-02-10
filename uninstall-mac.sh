#!/bin/bash
set -e

# ========== OS Check ==========
if [[ "$(uname)" != "Darwin" ]]; then
  echo "❌ This script is for macOS only. Detected non-macOS system — aborting!"
  exit 1
fi

echo "⚠️  This will remove all setup-mac.sh installations!"
read -p "Are you sure? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

# ========== Dotfiles Symlinks ==========
echo "==> Removing dotfiles symlinks..."
rm -f "$HOME/.config/nvim"
rm -f "$HOME/.config/tmux"
rm -f "$HOME/.config/spaceship"
rm -f "$HOME/.config/ghostty"
rm -f "$HOME/.config/neofetch"
rm -f "$HOME/.config/yabai"
rm -f "$HOME/.config/skhd"
rm -f "$HOME/.zshrc"
rm -f "$HOME/.hyper.js"
echo "✅ Symlinks removed"

# ========== Homebrew Packages ==========
echo "==> Removing Homebrew packages..."
brew remove -y git neovim tmux zsh trash 2>/dev/null || true
echo "✅ Homebrew packages removed"

# ========== NVM ==========
echo "==> Removing NVM..."
rm -rf "$HOME/.nvm"
echo "✅ NVM removed"

# ========== Bun ==========
echo "==> Removing Bun..."
rm -rf "$HOME/.bun"
echo "✅ Bun removed"

# ========== Rust ==========
echo "==> Removing Rust..."
rm -rf "$HOME/.cargo"
rm -rf "$HOME/.rustup"
echo "✅ Rust removed"

# ========== Tmux Plugin Manager ==========
echo "==> Removing TPM..."
rm -rf "$HOME/.config/tmux/plugins"
echo "✅ TPM removed"

# ========== Oh My Zsh ==========
echo "==> Removing Oh My Zsh..."
rm -rf "$HOME/.oh-my-zsh"
echo "✅ Oh My Zsh removed"

# ========== Done ==========
echo ""
echo "✅ Uninstall complete!"
echo "⚠️  To revert shell to bash, run: chsh -s /bin/bash"
