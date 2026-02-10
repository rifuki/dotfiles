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

# ========== Swap Setup ==========
if ! swapon --show | grep -q "/swapfile"; then
  echo "==> Creating 2GB swap file..."
  sudo fallocate -l 2G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile

  # Make swap persistent
  grep -q "/swapfile" /etc/fstab || echo "/swapfile swap swap defaults 0 0" | sudo tee -a /etc/fstab
  echo "✅ Swap created successfully"
else
  echo "✅ Swap already exists"
fi

# ========== Swappiness Configuration ==========
echo "==> Configuring swappiness..."
sudo sysctl -w vm.swappiness=30 > /dev/null 2>&1
grep -q "vm.swappiness" /etc/sysctl.conf || echo "vm.swappiness=30" | sudo tee -a /etc/sysctl.conf > /dev/null 2>&1
echo "✅ Swappiness set to 30"

# ========== System Dependencies ==========
echo "==> Installing system dependencies..."
sudo apt update
sudo apt install -y curl git unzip build-essential tmux zsh ripgrep

# ========== Neovim Installation ==========
if [ ! -x "$(command -v nvim)" ]; then
  echo "==> Installing Neovim (stable)..."
  NVIM_VERSION=$(curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
  curl -LO "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.tar.gz"
  tar xzf nvim-linux-x86_64.tar.gz
  sudo mv nvim-linux-x86_64 /opt/nvim
  sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
  rm -f nvim-linux-x86_64.tar.gz
  echo "✅ Neovim ${NVIM_VERSION} installed"
else
  echo "==> Neovim already installed at: $(command -v nvim) ($(nvim --version | head -1))"
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

# ========== Rust ==========
if ! command -v rustup &>/dev/null; then
  echo "==> Installing Rust (stable)..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
  source "$HOME/.cargo/env"
  echo "✅ Rust $(rustc --version) installed"
else
  echo "==> Rust already installed: $(rustc --version)"
fi

# ========== Gemini CLI ==========
if ! command -v gemini &>/dev/null; then
  echo "==> Installing Gemini CLI..."
  npm install -g @google/gemini-cli
  echo "✅ Gemini CLI installed"
else
  echo "==> Gemini CLI already installed"
fi

# ========== Bun ==========
if [ ! -d "$HOME/.bun" ]; then
  echo "==> Installing Bun..."
  curl -fsSL https://bun.sh/install | bash
  echo "✅ Bun installed"
else
  echo "==> Bun already installed: $("$HOME/.bun/bin/bun" --version)"
fi

# ========== fzf ==========
if [ ! -d "$HOME/.fzf" ]; then
  echo "==> Installing fzf..."
  git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  "$HOME/.fzf/install" --key-bindings --completion --no-update-rc
  echo "✅ fzf installed"
else
  echo "==> fzf already installed"
fi

# ========== eza ==========
if ! command -v eza &>/dev/null; then
  echo "==> Installing eza..."
  EZA_VERSION=$(curl -fsSL https://api.github.com/repos/eza-community/eza/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
  curl -LO "https://github.com/eza-community/eza/releases/download/${EZA_VERSION}/eza_x86_64-unknown-linux-musl.tar.gz"
  tar xzf eza_x86_64-unknown-linux-musl.tar.gz eza
  sudo mv eza /usr/local/bin/eza
  rm -f eza_x86_64-unknown-linux-musl.tar.gz
  echo "✅ eza installed"
else
  echo "==> eza already installed: $(eza --version | head -1)"
fi

# ========== Docker ==========
if ! command -v docker &>/dev/null; then
  echo "==> Installing Docker..."
  curl -fsSL https://get.docker.com | sh
  echo "✅ Docker installed"
else
  echo "==> Docker already installed: $(docker --version)"
fi

if ! groups "$USER" | grep -q docker; then
  echo "==> Adding $USER to docker group..."
  sudo usermod -aG docker "$USER"
  echo "✅ Done. Re-login required for group to take effect."
else
  echo "==> $USER already in docker group"
fi

# ========== Portainer ==========
if ! sudo docker ps -a --format '{{.Names}}' | grep -q "^portainer$"; then
  echo "==> Installing Portainer..."
  sudo docker volume create portainer_data
  sudo docker run -d \
    --name portainer \
    --restart=always \
    -p 9000:9000 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:latest
  echo "✅ Portainer running at http://$(hostname -I | awk '{print $1}'):9000"
else
  echo "==> Portainer already installed"
fi

# ========== Dotfiles ==========
if [ -d "daily-dotfiles" ]; then
  rm -rf daily-dotfiles
fi
git clone --depth=1 --branch vps https://github.com/rifuki/daily-dotfiles.git

if [ ! -d "$HOME/.config/nvim" ] || [ ! -d "$HOME/.config/tmux" ]; then
  echo "==> Installing dotfiles..."
  rm -rf ~/.config/.git ~/.config/.gitignore ~/.config/nvim ~/.config/tmux
fi

# Always update spaceship config
echo "==> Updating spaceship config..."
rm -rf ~/.config/spaceship
mkdir -p ~/.config
cp -r daily-dotfiles/. ~/.config/
rm -rf daily-dotfiles
echo "✅ Dotfiles installed"

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

# Cleanup old spaceship installation if exists (migration)
[ -d "$ZSH_CUSTOM/themes/spaceship" ] && rm -rf "$ZSH_CUSTOM/themes/spaceship"
[ -f "$ZSH_CUSTOM/themes/spaceship.zsh-theme" ] && rm -f "$ZSH_CUSTOM/themes/spaceship.zsh-theme"

if [ ! -d "$ZSH_CUSTOM/themes/spaceship-prompt" ]; then
  echo "==> Installing Spaceship theme..."
  git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
fi
# Always ensure symlink exists
[ ! -f "$ZSH_CUSTOM/themes/spaceship.zsh-theme" ] && \
  ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"

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
export SPACESHIP_CONFIG="\$HOME/.config/spaceship/spaceship.zsh"

export VISUAL=nvim
export EDITOR="\$VISUAL"

. "\$HOME/.cargo/env"
export BUN_INSTALL="\$HOME/.bun"
export PATH="\$BUN_INSTALL/bin:\$PATH"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

alias ls="eza --icons"
alias ll="eza -la --icons"
alias lt="eza --tree --icons"
EOF

# ========== Gemini API Key (Optional) ==========
echo "   Get your free API key at: https://aistudio.google.com/apikey"
read -p "==> Set up Gemini API key now? (yes/no): " GEMINI_SETUP < /dev/tty
if [ "$GEMINI_SETUP" = "yes" ]; then
  read -p "   Enter your Gemini API key: " GEMINI_KEY < /dev/tty
  echo "export GEMINI_API_KEY=\"$GEMINI_KEY\"" >> ~/.zshrc
  echo "✅ Gemini API key saved to ~/.zshrc"
else
  echo "⏭️  Skipping. To set up later, add to ~/.zshrc:"
  echo "   export GEMINI_API_KEY=\"your_key_here\""
fi

# ========== Set Zsh as Default Shell ==========
if [ "$SHELL" != "$(which zsh)" ]; then
  echo "==> Setting zsh as default shell..."
  sudo chsh -s "$(which zsh)" "$USER" 2>/dev/null || true
fi

# Fallback: auto-start zsh from .bashrc if chsh failed
grep -q "exec zsh" ~/.bashrc || cat <<'EOF' >> ~/.bashrc

# Auto start zsh
if [ -t 1 ] && [ -x "$(command -v zsh)" ]; then
  export SHELL=$(which zsh)
  exec zsh
fi
EOF

# ========== fail2ban ==========
echo "==> Configuring fail2ban..."
sudo apt install -y fail2ban
if [ ! -f /etc/fail2ban/jail.local ]; then
  sudo tee /etc/fail2ban/jail.local > /dev/null <<'EOF'
[sshd]
enabled = true
port = ssh
maxretry = 5
bantime = 1h
findtime = 10m
EOF
fi
sudo systemctl enable --now fail2ban
echo "✅ fail2ban enabled"

# ========== UFW (Firewall) ==========
echo "==> Configuring UFW..."
sudo apt install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw allow 9000/tcp
sudo ufw --force enable
echo "✅ UFW enabled"
sudo ufw status

# ========== Done ==========
echo "✅ Setup complete!"
echo "⚠️  Docker group requires SSH reconnect to take effect (docker without sudo)."
echo "👉 Switching to Zsh..."
exec zsh
