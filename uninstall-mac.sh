#!/bin/bash
set -e

# ========== OS Check ==========
if [[ "$(uname)" != "Darwin" ]]; then
  echo "❌ This script is for macOS only. Detected non-macOS system — aborting!"
  exit 1
fi

DOTFILES_DIR="$HOME/.dotfiles"

echo "⚠️  This will remove all setup-mac.sh installations!"
printf "Are you sure? (yes/no): " && read CONFIRM < /dev/tty
if [ "$CONFIRM" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

# ========== Backup User Configs ==========
# cp -rL to dereference symlinks and copy actual content
BACKUP_DIR="$HOME/.config/backup-uninstall-$(date +%Y%m%d-%H%M%S)"
_did_backup=0

if [ -d "$DOTFILES_DIR/.config" ]; then
  for _d in "$DOTFILES_DIR/.config"/*/; do
    _name="$(basename "$_d")"
    _p="$HOME/.config/$_name"
    if [ -e "$_p" ]; then
      [ "$_did_backup" = "0" ] && mkdir -p "$BACKUP_DIR" && echo "==> Backing up configs to $BACKUP_DIR..."
      cp -rL "$_p" "$BACKUP_DIR/" 2>/dev/null || true
      _did_backup=1
    fi
  done
fi
for _f in "$HOME/.zshrc" "$HOME/.hyper.js"; do
  if [ -e "$_f" ]; then
    [ "$_did_backup" = "0" ] && mkdir -p "$BACKUP_DIR" && echo "==> Backing up configs to $BACKUP_DIR..."
    cp -rL "$_f" "$BACKUP_DIR/" 2>/dev/null || true
    _did_backup=1
  fi
done
[ "$_did_backup" = "1" ] && echo "✅ Backups saved to: $BACKUP_DIR"

# ========== Dotfiles Symlinks ==========
echo "==> Removing dotfiles symlinks..."
if [ -d "$DOTFILES_DIR/.config" ]; then
  for _d in "$DOTFILES_DIR/.config"/*/; do
    rm -f "$HOME/.config/$(basename "$_d")"
  done
fi
rm -f "$HOME/.zshrc" "$HOME/.hyper.js"
echo "✅ Symlinks removed"

# ========== Homebrew Packages ==========
echo "==> Removing Homebrew packages..."
brew uninstall neovim tmux trash htop neofetch yazi gh 2>/dev/null || true
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

# ========== Oh My Zsh ==========
echo "==> Removing Oh My Zsh..."
rm -rf "$HOME/.oh-my-zsh"
echo "✅ Oh My Zsh removed"

# ========== Leftover Data Dirs ==========
echo "==> Removing leftover data directories..."
rm -rf "$HOME/.npm"
rm -rf "$HOME/.local/share/nvim"
rm -rf "$HOME/.local/state/nvim"
rm -rf "$HOME/.local/share/tmux"
echo "✅ Leftover data removed"

# ========== Dotfiles Repo ==========
echo "==> Removing dotfiles repo..."
rm -rf "$HOME/.dotfiles"
echo "✅ Dotfiles repo removed"

# ========== Done ==========
echo ""
echo "✅ Uninstall complete!"
