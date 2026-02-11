#!/bin/bash
set -e

# ========== OS Check ==========
if [[ "$(uname)" != "Darwin" ]]; then
  echo "❌ This script is for macOS only. Detected non-macOS system — aborting!"
  exit 1
fi

# ========== Clone Dotfiles Repo ==========
DOTFILES_DIR="$HOME/.dotfiles"
DOTFILES_REPO="https://github.com/rifuki/.dotfiles.git"

if [ ! -d "$DOTFILES_DIR/.git" ]; then
  echo "==> Cloning dotfiles repo..."
  git clone --branch backup/mac-2026-02-10 "$DOTFILES_REPO" "$DOTFILES_DIR"
  echo "✅ Dotfiles cloned to $DOTFILES_DIR"
else
  echo "✅ Dotfiles repo already exists, pulling latest..."
  git -C "$DOTFILES_DIR" pull --ff-only 2>/dev/null || echo "⚠️  Could not pull dotfiles (local changes?)"
fi

# ========== Xcode Command Line Tools ==========
echo "==> Checking Xcode Command Line Tools..."
if ! command -v xcode-select &>/dev/null || ! xcode-select -p &>/dev/null; then
  printf "==> Xcode CLT not found. Install now? (yes/no): " && read XCD_INSTALL < /dev/tty
  if [ "$XCD_INSTALL" = "yes" ]; then
    echo "==> Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "⚠️  Please complete the Xcode installation and re-run this script."
    exit 0
  else
    echo "⏭️  Skipping Xcode CLT. Note: Some tools may not work without it."
  fi
else
  echo "✅ Xcode CLT already installed"
fi

# ========== Homebrew ==========
if ! command -v brew &>/dev/null; then
  echo "==> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv bash)"
  echo "✅ Homebrew installed"
else
  echo "✅ Homebrew already installed: $(brew --version | head -1)"
fi

# ========== Neovim ==========
if ! command -v nvim &>/dev/null; then
  echo "==> Installing Neovim..."
  brew install neovim
  echo "✅ Neovim $(nvim --version | head -1) installed"
else
  echo "✅ Neovim already installed: $(nvim --version | head -1)"
fi

# ========== Tmux ==========
if ! command -v tmux &>/dev/null; then
  echo "==> Installing Tmux..."
  brew install tmux
  echo "✅ Tmux installed"
else
  echo "✅ Tmux already installed: $(tmux -V)"
fi

# ========== Trash (safe rm) ==========
if ! command -v trash &>/dev/null; then
  echo "==> Installing trash..."
  brew install trash
  echo "✅ trash installed"
else
  echo "✅ trash already installed"
fi

# ========== Htop ==========
if ! command -v htop &>/dev/null; then
  echo "==> Installing htop..."
  brew install htop
  echo "✅ htop installed"
else
  echo "✅ htop already installed: $(htop --version | head -1)"
fi

# ========== Neofetch ==========
if ! command -v neofetch &>/dev/null; then
  echo "==> Installing neofetch..."
  brew install neofetch
  echo "✅ neofetch installed"
else
  echo "✅ neofetch already installed"
fi

# ========== Yazi ==========
if ! command -v yazi &>/dev/null; then
  echo "==> Installing yazi..."
  brew install yazi
  echo "✅ yazi installed"
else
  echo "✅ yazi already installed: $(yazi --version)"
fi

# ========== GitHub CLI ==========
if ! command -v gh &>/dev/null; then
  echo "==> Installing GitHub CLI..."
  brew install gh
  echo "✅ gh installed"
else
  echo "✅ gh already installed: $(gh --version | head -1)"
fi

# ========== Oh My Zsh ==========
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "==> Installing Oh My Zsh..."
  RUNZSH=no KEEP_ZSHRC=yes CHSH=no bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || {
    echo "❌ Oh My Zsh installation failed!"
    exit 1
  }
fi

ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

echo "==> Installing Oh My Zsh plugins..."
[[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]] && \
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

[[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]] && \
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

[[ ! -d "$ZSH_CUSTOM/plugins/spaceship-ember" ]] && \
  git clone https://github.com/spaceship-prompt/spaceship-ember.git "$ZSH_CUSTOM/plugins/spaceship-ember"

[[ ! -d "$ZSH_CUSTOM/plugins/spaceship-vi-mode" ]] && \
  git clone https://github.com/spaceship-prompt/spaceship-vi-mode.git "$ZSH_CUSTOM/plugins/spaceship-vi-mode"

# Cleanup old spaceship installation
[ -d "$ZSH_CUSTOM/themes/spaceship" ] && rm -rf "$ZSH_CUSTOM/themes/spaceship"
[ -f "$ZSH_CUSTOM/themes/spaceship.zsh-theme" ] && rm -f "$ZSH_CUSTOM/themes/spaceship.zsh-theme"

# Install Spaceship theme
if [ ! -d "$ZSH_CUSTOM/themes/spaceship-prompt" ]; then
  echo "==> Installing Spaceship theme..."
  git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
fi

# Ensure symlink exists
[ ! -f "$ZSH_CUSTOM/themes/spaceship.zsh-theme" ] && \
  ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"

echo "✅ Oh My Zsh plugins and theme installed"

# ========== NVM ==========
export NVM_DIR="$HOME/.nvm"

if [ ! -d "$NVM_DIR" ]; then
  echo "==> Installing NVM..."
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | PROFILE=/dev/null bash
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
else
  echo "✅ NVM already installed, loading..."
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

if ! nvm ls 22 &>/dev/null; then
  echo "==> Installing Node.js 22 via NVM..."
  nvm install 22
else
  echo "✅ Node.js 22 already installed."
fi

nvm use 22

# ========== Bun ==========
if [ ! -d "$HOME/.bun" ]; then
  echo "==> Installing Bun..."
  curl -fsSL https://bun.sh/install | bash
  echo "✅ Bun installed"
else
  echo "✅ Bun already installed: $("$HOME/.bun/bin/bun" --version)"
fi

# ========== Rust ==========
if [ ! -f "$HOME/.cargo/bin/rustup" ]; then
  echo "==> Installing Rust (stable)..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --no-modify-path
  source "$HOME/.cargo/env"
  echo "✅ Rust $("$HOME/.cargo/bin/rustc" --version) installed"
else
  echo "✅ Rust already installed: $("$HOME/.cargo/bin/rustc" --version)"
fi

# ========== Dotfiles Symlink ==========
echo "==> Setting up dotfiles symlinks..."
# When run via curl/process-substitution, BASH_SOURCE is not a real file path
_src="${BASH_SOURCE[0]:-}"
if [[ "$_src" == /* ]] && [[ -f "$_src" ]]; then
  REPO_DIR="$(cd "$(dirname "$_src")" && pwd)"
else
  REPO_DIR="$DOTFILES_DIR"
fi

# Backup existing configs
# Only backup real directories (not symlinks) — symlinks are already ours
_needs_backup=0
for _d in nvim tmux spaceship; do
  [ -d "$HOME/.config/$_d" ] && [ ! -L "$HOME/.config/$_d" ] && _needs_backup=1
done
[ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ] && _needs_backup=1
[ -f "$HOME/.hyper.js" ] && [ ! -L "$HOME/.hyper.js" ] && _needs_backup=1

if [ "$_needs_backup" = "1" ]; then
  BACKUP_DIR="$HOME/.config/backup-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$BACKUP_DIR"
  echo "==> Backing up existing configs to $BACKUP_DIR..."
  for _d in nvim tmux spaceship; do
    [ -d "$HOME/.config/$_d" ] && [ ! -L "$HOME/.config/$_d" ] && mv "$HOME/.config/$_d" "$BACKUP_DIR/"
  done
  [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ] && mv "$HOME/.zshrc" "$BACKUP_DIR/.zshrc.bak"
  [ -f "$HOME/.hyper.js" ] && [ ! -L "$HOME/.hyper.js" ] && mv "$HOME/.hyper.js" "$BACKUP_DIR/.hyper.js.bak"
  echo "✅ Backups created"
fi

# Create symlinks
mkdir -p "$HOME/.config"
ln -sf "$REPO_DIR/.config/nvim" "$HOME/.config/nvim"
ln -sf "$REPO_DIR/.config/tmux" "$HOME/.config/tmux"
ln -sf "$REPO_DIR/.config/spaceship" "$HOME/.config/spaceship"
ln -sf "$REPO_DIR/.config/ghostty" "$HOME/.config/ghostty"
ln -sf "$REPO_DIR/.config/neofetch" "$HOME/.config/neofetch"
ln -sf "$REPO_DIR/.config/yabai" "$HOME/.config/yabai"
ln -sf "$REPO_DIR/.config/skhd" "$HOME/.config/skhd"
ln -sf "$REPO_DIR/.zshrc" "$HOME/.zshrc"
ln -sf "$REPO_DIR/.hyper.js" "$HOME/.hyper.js"

echo "✅ Dotfiles symlinked"

# ========== Cleanup Shell Profiles ==========
# Remove entries added by installers (cargo, nvm) — everything is in .zshrc
echo "==> Cleaning up shell profile files..."
for _f in "$HOME/.zprofile" "$HOME/.zshenv" "$HOME/.profile" "$HOME/.bash_profile" "$HOME/.bashrc"; do
  [ -f "$_f" ] || continue
  grep -qE 'cargo/env|NVM_DIR|nvm\.sh|bun\.sh|BUN_INSTALL|_bun' "$_f" 2>/dev/null || continue
  grep -vE 'cargo/env|NVM_DIR|nvm\.sh|bun\.sh|BUN_INSTALL|_bun|Added by.*installer' "$_f" > "${_f}.tmp" || true
  if [ -s "${_f}.tmp" ]; then
    mv "${_f}.tmp" "$_f"
  else
    rm -f "${_f}.tmp" "$_f"
  fi
  echo "   Cleaned: $_f"
done
echo "✅ Shell profiles cleaned"

# ========== Tmux Plugin Manager ==========
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
  echo "==> Installing TPM..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi
echo "==> Installing Tmux plugins..."
if [ -x "$TPM_DIR/bin/install_plugins" ]; then
  "$TPM_DIR/bin/install_plugins"
else
  echo "⚠️ TPM install_plugins not found, skipping..."
fi

# ========== Spaceship Config ==========
echo "==> Setting up Spaceship prompt..."
if [ -f "$HOME/.oh-my-zsh/custom/themes/spaceship.zsh-theme" ]; then
  export SPACESHIP_CONFIG="$HOME/.config/spaceship/spaceship.zsh"
  echo "✅ Spaceship config linked"
else
  echo "⚠️ Spaceship theme not found, skipping config..."
fi

# ========== Git Config ==========
GIT_NAME_SET=$(git config --global user.name 2>/dev/null)
GIT_EMAIL_SET=$(git config --global user.email 2>/dev/null)
if [ -z "$GIT_NAME_SET" ] || [ -z "$GIT_EMAIL_SET" ]; then
  echo "==> Configuring Git..."
  printf "   Enter your Git name: " && read GIT_NAME < /dev/tty
  printf "   Enter your Git email: " && read GIT_EMAIL < /dev/tty
  git config --global user.name "$GIT_NAME"
  git config --global user.email "$GIT_EMAIL"
  echo "✅ Git config set"
else
  echo "✅ Git already configured: $GIT_NAME_SET <$GIT_EMAIL_SET>"
fi

# ========== Set Zsh as Default Shell ==========
if [ "$SHELL" != "$(which zsh)" ]; then
  echo "==> Setting zsh as default shell..."
  chsh -s "$(which zsh)" || echo "⚠️  chsh failed. Run: chsh -s $(which zsh)"
fi

# ========== Sui Move Analyzer ==========
if [ ! -f "$HOME/.cargo/bin/sui-move-analyzer" ]; then
  printf "==> Install sui-move-analyzer? (yes/no): " && read SUI_INSTALL < /dev/tty
  if [ "$SUI_INSTALL" = "yes" ]; then
    echo "==> Spawning sui-move-analyzer install in tmux background session..."
    tmux new-session -d -s sui-install -n "sui-move-analyzer" \
      "cargo install --git https://github.com/movebit/sui-move-analyzer.git; \
       echo ''; \
       echo '✅ sui-move-analyzer installed! You can close this window.'; \
       read _dummy"
    echo "✅ Install started in background!"
    echo "   Monitor progress : tmux attach -t sui-install"
    echo "   Detach from tmux : Ctrl+b then d"
  else
    echo "⏭️  Skipping sui-move-analyzer."
    echo "   To install later, run:"
    echo "   cargo install --git https://github.com/movebit/sui-move-analyzer.git"
  fi
else
  echo "✅ sui-move-analyzer already installed"
fi

# ========== Done ==========
echo ""
echo "✅ Setup complete!"
echo "👉 Please restart your terminal or run: exec zsh"
