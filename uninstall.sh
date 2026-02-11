#!/bin/bash
set -e

# ========== OS Check ==========
if [[ "$(uname)" != "Darwin" ]]; then
  echo "❌ This script is for macOS only. Detected non-macOS system — aborting!"
  exit 1
fi

# ========== Confirm Helper ==========
confirm() {
  # $1 = prompt message
  local _ans
  if [ -t 0 ] || [ -c /dev/tty ]; then
    printf "%s [y/n]: " "$1"
    read -r _ans < /dev/tty
    case "${_ans}" in
      [yY]|[yY][eE][sS]) return 0 ;;
      *) return 1 ;;
    esac
  fi
  return 1  # non-interactive: default no
}

# ========== Welcome Banner ==========
cat << 'EOF'
================================================
     dotfiles uninstaller — macOS
================================================
This script will remove:
  • NVM (~/.nvm) - Node Version Manager
  • Bun (~/.bun) - JavaScript runtime
  • Rust (~/.cargo) - Rust toolchain
  • Oh My Zsh (~/.oh-my-zsh) - Zsh framework
  • Dotfiles symlinks (.zshrc, .hyper.js, .config/*)
  • Cache files (.zcompdump, .node_repl_history,
    .cache/nvim, .config/github-copilot)

This will NOT remove:
  • Homebrew or any Homebrew packages
  • .zsh_history (backed up during install)
  • Backed up configs (if available for restore)
================================================
EOF

if ! confirm "Proceed with uninstallation?"; then
  echo "⏭️  Uninstallation cancelled."
  exit 0
fi

echo ""

# ========== Backup Current Configs ==========
# Create backup before removing anything (safety first!)
DOTFILES_DIR="$HOME/.dotfiles"
UNINSTALL_BACKUP_DIR="$HOME/.config/backup-uninstall-$(date +%Y%m%d-%H%M%S)"
_did_backup=0

echo "==> Creating backup of current configs..."
# Only backup .config directories managed by dotfiles repo
for _d in "$DOTFILES_DIR/.config"/*/; do
  _name="$(basename "$_d")"
  _home_d="$HOME/.config/$_name"
  if [ -e "$_home_d" ]; then
    [ "$_did_backup" = "0" ] && mkdir -p "$UNINSTALL_BACKUP_DIR/.config"
    cp -rL "$_home_d" "$UNINSTALL_BACKUP_DIR/.config/" 2>/dev/null || true
    _did_backup=1
  fi
done
for _f in "$HOME/.zshrc" "$HOME/.hyper.js" "$HOME/.zsh_history"; do
  if [ -e "$_f" ]; then
    [ "$_did_backup" = "0" ] && mkdir -p "$UNINSTALL_BACKUP_DIR"
    cp -L "$_f" "$UNINSTALL_BACKUP_DIR/" 2>/dev/null || true
    _did_backup=1
  fi
done
[ "$_did_backup" = "1" ] && echo "✅ Configs backed up to: $UNINSTALL_BACKUP_DIR" || echo "✅ No configs to backup"

# ========== Remove Symlinks ==========
echo "==> Removing dotfiles symlinks..."
rm -f "$HOME/.zshrc"
rm -f "$HOME/.hyper.js"
for _d in "$HOME/.config"/*/; do
  if [ -L "$_d" ]; then
    rm -f "$_d"
  fi
done
echo "✅ Symlinks removed"

# ========== Homebrew Packages ==========
if confirm "Remove Homebrew packages (neovim, tmux, ghostty, etc.)?"; then
  echo "==> Removing Homebrew packages..."
  brew uninstall neovim tmux trash htop neofetch yazi gh 2>/dev/null || true
  brew uninstall --cask ghostty 2>/dev/null || true
  echo "✅ Homebrew packages removed"
else
  echo "⏭️  Skipping Homebrew packages removal"
fi

# ========== Remove NVM ==========
if [ -d "$HOME/.nvm" ]; then
  echo "==> Removing NVM..."
  rm -rf "$HOME/.nvm"
  echo "✅ NVM removed"
else
  echo "✅ NVM not found"
fi

# ========== Remove Bun ==========
if [ -d "$HOME/.bun" ]; then
  echo "==> Removing Bun..."
  rm -rf "$HOME/.bun"
  echo "✅ Bun removed"
else
  echo "✅ Bun not found"
fi

# ========== Remove Rust ==========
if [ -d "$HOME/.cargo" ] || [ -d "$HOME/.rustup" ]; then
  echo "==> Removing Rust..."
  rm -rf "$HOME/.cargo"
  rm -rf "$HOME/.rustup"
  echo "✅ Rust removed"
else
  echo "✅ Rust not found"
fi

# ========== Remove Oh My Zsh ==========
if confirm "Remove Oh My Zsh? (custom configs will be preserved in backup)"; then
  echo "==> Removing Oh My Zsh..."
  rm -rf "$HOME/.oh-my-zsh"
  echo "✅ Oh My Zsh removed"
else
  echo "⏭️  Skipping Oh My Zsh removal"
fi

# ========== Remove Cache Files ==========
echo "==> Cleaning up cache files..."
rm -f "$HOME/.zcompdump"
rm -f "$HOME/.node_repl_history"
rm -rf "$HOME/.cache/nvim" 2>/dev/null || true
rm -rf "$HOME/.config/github-copilot" 2>/dev/null || true
echo "✅ Cache files removed"

# ========== Deep Clean Residue ==========
if confirm "Perform deep clean? (Removes .zsh_history, .wakatime, and other residues)"; then
  echo "==> Cleaning up residue files..."
  rm -f "$HOME"/.zcompdump*
  rm -f "$HOME/.zsh_history"
  rm -rf "$HOME/.zsh_sessions"
  rm -f "$HOME/.node_repl_history"
  rm -f "$HOME/.gitconfig"
  rm -f "$HOME/.gitignore_global"
  rm -f "$HOME/.hushlogin"
  rm -rf "$HOME/.local/share/nvim"
  rm -rf "$HOME/.local/state/nvim"
  rm -rf "$HOME/.config/github-copilot"
  rm -rf "$HOME/.wakatime*"
  echo "✅ Residue files removed"
else
  echo "⏭️  Skipping deep clean"
fi

# ========== Done ==========
echo ""
echo "✅ Uninstallation complete!"
echo "📦 Backup saved to: $UNINSTALL_BACKUP_DIR"
echo "👉 You may need to restart your terminal or reset your shell configuration"
