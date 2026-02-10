#!/bin/bash
set -e

# ========== OS Check ==========
if [[ "$(uname)" == "Darwin" ]]; then
  echo "❌ Detected macOS — aborting! For macOS, use a separate repo."
  exit 1
fi

if ! command -v apt &>/dev/null; then
  echo "❌ This script requires apt (Ubuntu/Debian only). Non-Ubuntu distro detected — aborting!"
  exit 1
fi

echo "⚠️  This will remove all setup-wsl.sh installations!"
read -p "Are you sure? (yes/no): " CONFIRM < /dev/tty
if [ "$CONFIRM" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

# ========== Neovim ==========
echo "==> Removing Neovim..."
sudo rm -f /usr/local/bin/nvim
sudo rm -rf /opt/nvim
echo "✅ Neovim removed"

# ========== NVM & Node ==========
echo "==> Removing NVM & Node.js..."
rm -rf "$HOME/.nvm"
echo "✅ NVM removed"

# ========== Rust ==========
echo "==> Removing Rust..."
rm -rf "$HOME/.cargo" "$HOME/.rustup"
echo "✅ Rust removed"

# ========== Dotfiles ==========
echo "==> Removing dotfiles..."
rm -rf ~/.config/nvim ~/.config/tmux ~/.config/spaceship
rm -f ~/.config/.gitignore
echo "✅ Dotfiles removed"

# ========== Tmux Plugins ==========
echo "==> Removing TPM & plugins..."
rm -rf ~/.config/tmux/plugins
echo "✅ TPM removed"

# ========== Oh My Zsh ==========
echo "==> Removing Oh My Zsh..."
rm -rf "$HOME/.oh-my-zsh"
echo "✅ Oh My Zsh removed"

# ========== .zshrc ==========
echo "==> Removing .zshrc..."
rm -f ~/.zshrc
echo "✅ .zshrc removed"

# ========== Revert WSL shell to bash ==========
echo "==> Removing zsh auto-start from ~/.bashrc..."
sed -i '/# Auto start zsh in WSL/,/^fi$/d' ~/.bashrc
echo "✅ Shell reverted to bash"

# ========== Done ==========
echo ""
echo "✅ Uninstall complete! Please restart your WSL terminal."
