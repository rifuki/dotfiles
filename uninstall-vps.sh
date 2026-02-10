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

echo "⚠️  This will remove all setup-vps.sh installations!"
read -p "Are you sure? (yes/no): " CONFIRM < /dev/tty
if [ "$CONFIRM" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

# ========== Swap ==========
echo "==> Removing swap..."
if swapon --show | grep -q "/swapfile"; then
  sudo swapoff /swapfile
fi
[ -f /swapfile ] && sudo rm -f /swapfile
sudo sed -i '/\/swapfile/d' /etc/fstab
sudo sed -i '/vm.swappiness/d' /etc/sysctl.conf
echo "✅ Swap removed"

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

# ========== Docker ==========
echo "==> Removing Docker..."
sudo apt remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
sudo rm -rf /var/lib/docker /etc/docker
rm -rf "$HOME/.docker"
echo "✅ Docker removed"

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

# ========== Revert shell to bash ==========
echo "==> Reverting shell to bash..."
chsh -s "$(which bash)" 2>/dev/null || true
sed -i '/# Auto start zsh/,/^fi$/d' ~/.bashrc
echo "✅ Shell reverted to bash"

# ========== Done ==========
echo ""
echo "✅ Uninstall complete! Please restart your terminal."
