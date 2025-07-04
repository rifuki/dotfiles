#!/bin/bash
set -e

# ========== Detect WSL ==========
IS_WSL=false
if grep -qi microsoft /proc/version; then
  IS_WSL=true
fi

# ========== System Dependencies ==========
echo "==> Installing system dependencies..."
sudo apt update
sudo apt install -y curl git unzip build-essential cmake ninja-build gettext tmux zsh

# ========== Neovim Installation ==========
if [ ! -x "$(command -v nvim)" ]; then
  echo "==> Neovim not found, building from source..."
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
if ! command -v npm &>/dev/null; then
  echo "==> Installing Node.js via NVM..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  # Persist in .zshrc
  grep -q 'export NVM_DIR' ~/.zshrc || cat <<EOF >> ~/.zshrc
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"
EOF

  nvm install 22
else
  echo "==> Node.js & npm already installed."
fi

# ========== Dotfiles ==========
echo "==> Cloning dotfiles..."
git clone https://github.com/rifuki/rifuki-dotvimux.git

echo "==> Cleaning old configs..."
rm -rf ~/.config/.git ~/.config/.gitignore ~/.config/nvim ~/.config/tmux

echo "==> Copying configs..."
mkdir -p ~/.config
cp -r rifuki-dotvimux/. ~/.config/
rm -rf rifuki-dotvimux

# ========== Tmux Plugin Manager ==========
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
  echo "==> Installing TPM..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi
echo "==> Installing Tmux plugins..."
"$TPM_DIR/bin/install_plugins"

# ========== Oh My Zsh + Plugins + Theme ==========
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "==> Installing Oh My Zsh..."
  RUNZSH=no KEEP_ZSHRC=yes CHSH=no bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

[[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]] && \
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

[[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]] && \
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

[[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]] && \
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"

# ========== .zshrc Config ==========
echo "==> Writing ~/.zshrc..."
cat > ~/.zshrc <<EOF
export ZSH="\$HOME/.oh-my-zsh"
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"

ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source \$ZSH/oh-my-zsh.sh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
echo 'export VISUAL=nvim' >> ~/.zshrc
echo 'export EDITOR="$VISUAL"' >> ~/.zshrc
EOF

# ========== WSL Shell Auto-switch ==========
if [ "$IS_WSL" = true ]; then
  echo "==> WSL detected. Adding zsh to ~/.bashrc..."
  grep -q "exec zsh" ~/.bashrc || cat <<EOF >> ~/.bashrc

# Auto start zsh in WSL
if [ -t 1 ] && [ -x "\$(command -v zsh)" ]; then
  export SHELL=\$(which zsh)
  exec zsh
fi
EOF
else
  # Try chsh on non-WSL
  if [ "$SHELL" != "$(which zsh)" ]; then
    echo "==> Setting zsh as default shell..."
    chsh -s "$(which zsh)" || echo "⚠️ Failed to change shell. Try manually with: chsh -s $(which zsh)"
  fi
fi

# ========== Done ==========
echo "✅ Setup complete!"
if [ "$IS_WSL" = true ]; then
  echo "👉 Please restart your WSL terminal (e.g. close and reopen)"
else
  echo "👉 Run 'exec zsh' or restart terminal to enjoy Zsh"
fi
