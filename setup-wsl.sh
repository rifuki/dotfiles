#!/bin/bash
set -e

# ========== System Dependencies ==========
echo "==> Installing system dependencies..."
sudo apt update
sudo apt install -y curl git unzip build-essential cmake ninja-build gettext tmux zsh

# ========== Neovim Installation ==========
if [ ! -x "$(command -v nvim)" ]; then
  echo "==> Neovim not found, building from source..."

  if [ -d "neovim" ]; then
    echo "==> Removing existing neovim directory..."
    rm -rf neovim
  fi

  git clone https://github.com/neovim/neovim.git
  cd neovim
  make CMAKE_BUILD_TYPE=RelWithDebInfo
  sudo make install
  cd ..
  rm -rf neovim
else
  echo "==> Neovim already installed at: $(command -v nvim)"
fi

# ========== Node.js & NVM ==========
export NVM_DIR="$HOME/.nvm"

if [ ! -d "$NVM_DIR" ]; then
  echo "==> Installing NVM..."
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
else
  echo "==> NVM already installed, loading..."
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

if ! nvm ls 22 &>/dev/null; then
  echo "==> Installing Node.js 22 via NVM..."
  nvm install 22
else
  echo "==> Node.js 22 already installed."
fi

nvm use 22

# ========== Dotfiles ==========
if [ ! -d "$HOME/.config/nvim" ] || [ ! -d "$HOME/.config/tmux" ]; then
  echo "==> Cloning dotfiles..."
  if [ -d "daily-dotfiles" ]; then
    rm -rf daily-dotfiles
  fi
  git clone --depth=1 https://github.com/rifuki/daily-dotfiles.git

  echo "==> Cleaning old configs..."
  rm -rf ~/.config/.git ~/.config/.gitignore ~/.config/nvim ~/.config/tmux ~/.config/spaceship

  echo "==> Copying configs..."
  mkdir -p ~/.config
  cp -r daily-dotfiles/. ~/.config/
  rm -rf daily-dotfiles
  echo "✅ Dotfiles installed"
else
  echo "✅ Dotfiles already exist"
fi

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

# ========== Oh My Zsh + Plugins + Theme ==========
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "==> Installing Oh My Zsh..."
  RUNZSH=no KEEP_ZSHRC=yes CHSH=no bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || {
    echo "❌ Oh My Zsh installation failed!"
    exit 1
  }
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "❌ Oh My Zsh directory not found after installation!"
  exit 1
fi

ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

[[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]] && \
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

[[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]] && \
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

[[ ! -d "$ZSH_CUSTOM/plugins/spaceship-ember" ]] && \
  git clone https://github.com/spaceship-prompt/spaceship-ember.git "$ZSH_CUSTOM/plugins/spaceship-ember"

[[ ! -d "$ZSH_CUSTOM/plugins/spaceship-vi-mode" ]] && \
  git clone https://github.com/spaceship-prompt/spaceship-vi-mode.git "$ZSH_CUSTOM/plugins/spaceship-vi-mode"

if [ ! -d "$ZSH_CUSTOM/themes/spaceship-prompt" ]; then
  echo "==> Installing Spaceship theme..."
  git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
  ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
fi

# ========== .zshrc Config ==========
echo "==> Writing ~/.zshrc..."
cat > ~/.zshrc <<EOF
export ZSH="\$HOME/.oh-my-zsh"
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"

ZSH_THEME="spaceship"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting spaceship-ember spaceship-vi-mode)

source \$ZSH/oh-my-zsh.sh
SPACESHIP_PROMPT_ADD_NEWLINE=false

export VISUAL=nvim
export EDITOR="\$VISUAL"
EOF

# ========== WSL Shell Auto-switch ==========
echo "==> WSL detected. Adding zsh to ~/.bashrc..."
grep -q "exec zsh" ~/.bashrc || cat <<EOF >> ~/.bashrc

# Auto start zsh in WSL
if [ -t 1 ] && [ -x "\$(command -v zsh)" ]; then
  export SHELL=\$(which zsh)
  exec zsh
fi
EOF

# ========== Done ==========
echo "✅ Setup complete!"
echo "👉 Please restart your WSL terminal (e.g. close and reopen)"
