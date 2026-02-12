#!/bin/bash
set -e

# ========== Colors ==========
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ========== Helpers ==========
step()     { echo -e "\n${BOLD}${CYAN}  ◆ $1${NC}"; }
done_msg() { echo -e "  ${GREEN}✔${NC} $1"; }
info_msg() { echo -e "  ${BLUE}▸${NC} $1"; }
warn_msg() { echo -e "  ${YELLOW}▸${NC} $1"; }
fail_msg() { echo -e "  ${RED}✖${NC} $1"; }

confirm() {
  local _ans
  if [ -t 0 ] || [ -c /dev/tty ]; then
    printf "    %s [y/n]: " "$1"
    read -r _ans < /dev/tty
    case "${_ans}" in
      [yY]|[yY][eE][sS]) return 0 ;;
      *) return 1 ;;
    esac
  fi
  return 1
}

# ========== OS Check ==========
if [[ "$(uname)" != "Darwin" ]]; then
  echo -e "${RED}❌ This script is for macOS only.${NC}"
  exit 1
fi

# ========== TTY Check ==========
if [ ! -t 0 ] && [ ! -c /dev/tty ]; then
  echo -e "${RED}❌ This script requires an interactive terminal.${NC}"
  exit 1
fi

# ========== Xcode Command Line Tools (PREREQUISITE) ==========
step "Checking Xcode Command Line Tools"
if ! command -v xcode-select &>/dev/null || ! xcode-select -p &>/dev/null; then
  warn_msg "Xcode CLT not found"
  info_msg "Installing Xcode Command Line Tools..."
  xcode-select --install
  echo ""
  echo -e "    ${YELLOW}⚠️  Please follow the popup to install Xcode CLT.${NC}"
  echo -e "    ${YELLOW}⚠️  This may take 5-10 minutes.${NC}"
  echo -e "    ${YELLOW}⚠️  The script will continue automatically when done.${NC}"
  echo ""

  # Poll for installation completion (max 30 minutes)
  _timeout=1800
  _elapsed=0
  while [ $_elapsed -lt $_timeout ]; do
    if xcode-select -p &>/dev/null; then
      done_msg "Xcode CLT installation detected!"
      break
    fi
    sleep 5
    ((_elapsed += 5))
    if [ $((_elapsed % 30)) -eq 0 ]; then
      echo -e "    ${DIM}Still waiting for Xcode CLT... ($_elapsed/${_timeout}s)${NC}"
    fi
  done

  if ! xcode-select -p &>/dev/null; then
    fail_msg "Xcode CLT installation timeout or failed"
    echo -e "    ${DIM}Please install manually and re-run this script${NC}"
    exit 1
  fi
else
  done_msg "Xcode CLT already installed"
fi

echo ""

# ========== Detect Current State ==========
LABELS=()
DESCRIPTIONS=()
SELECTED=()
STATUS=()

# 0: Homebrew Formulae
LABELS+=("Homebrew Formulae")
DESCRIPTIONS+=("neovim, tmux, trash, htop, ripgrep, starship, neofetch, yazi, gh")
SELECTED+=(1)
_fi=0; _ft=9
for _cmd in nvim tmux trash htop rg starship neofetch yazi gh; do
  command -v "$_cmd" &>/dev/null && ((_fi++)) || true
done
if [ "$_fi" = "$_ft" ]; then STATUS+=("all installed")
elif [ "$_fi" -gt 0 ]; then STATUS+=("${_fi}/${_ft} installed")
else STATUS+=(""); fi

# 1: Yabai + Skhd
LABELS+=("Yabai + Skhd")
DESCRIPTIONS+=("Tiling WM + hotkey daemon")
SELECTED+=(1)
command -v yabai &>/dev/null && STATUS+=("installed") || STATUS+=("")

# 2: Ghostty + Font
LABELS+=("Ghostty + Nerd Font")
DESCRIPTIONS+=("Ghostty terminal + JetBrainsMono")
SELECTED+=(1)
[ -d "/Applications/Ghostty.app" ] && STATUS+=("installed") || STATUS+=("")

# 3: Cloudflare WARP + Hot
LABELS+=("Cloudflare WARP + Hot")
DESCRIPTIONS+=("Menu bar: VPN + thermal monitor")
SELECTED+=(1)
[ -d "/Applications/Cloudflare WARP.app" ] && STATUS+=("installed") || STATUS+=("")

# 4: Google Chrome
LABELS+=("Google Chrome")
DESCRIPTIONS+=("Browser")
SELECTED+=(1)
[ -d "/Applications/Google Chrome.app" ] && STATUS+=("installed") || STATUS+=("")

# 5: OrbStack
LABELS+=("OrbStack")
DESCRIPTIONS+=("Docker & Linux VM runtime")
SELECTED+=(1)
[ -d "/Applications/OrbStack.app" ] && STATUS+=("installed") || STATUS+=("")

# 6: Oh My Zsh
LABELS+=("Oh My Zsh")
DESCRIPTIONS+=("Zsh framework + plugins")
SELECTED+=(1)
[ -d "$HOME/.oh-my-zsh" ] && STATUS+=("installed") || STATUS+=("")

# 7: NVM + Node
LABELS+=("NVM + Node 24")
DESCRIPTIONS+=("Node Version Manager + Node.js")
SELECTED+=(1)
[ -d "$HOME/.nvm" ] && STATUS+=("installed") || STATUS+=("")

# 8: Bun
LABELS+=("Bun")
DESCRIPTIONS+=("JavaScript runtime")
SELECTED+=(1)
[ -d "$HOME/.bun" ] && STATUS+=("installed") || STATUS+=("")

# 9: Rust
LABELS+=("Rust")
DESCRIPTIONS+=("Rust toolchain via rustup")
SELECTED+=(1)
[ -f "$HOME/.cargo/bin/rustup" ] && STATUS+=("installed") || STATUS+=("")

# 10: suiup + Sui Testnet
LABELS+=("suiup + Sui Testnet")
DESCRIPTIONS+=("Sui version manager + latest testnet binary")
SELECTED+=(1)
[ -f "$HOME/.local/bin/suiup" ] && STATUS+=("installed") || STATUS+=("")

# 11: sui-move-analyzer
LABELS+=("sui-move-analyzer")
DESCRIPTIONS+=("Sui Move language server (~10min)")
SELECTED+=(1)
[ -f "$HOME/.cargo/bin/sui-move-analyzer" ] && STATUS+=("installed") || STATUS+=("")

# 12: SSH Keys (iCloud)
LABELS+=("SSH Keys (iCloud)")
DESCRIPTIONS+=("Symlink ~/.ssh from iCloud Drive")
_icloud_base="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
if [ -L "$HOME/.ssh" ]; then
  SELECTED+=(1); STATUS+=("symlinked")
elif [ -d "$_icloud_base" ]; then
  SELECTED+=(1); STATUS+=("iCloud available")
else
  SELECTED+=(0); STATUS+=("iCloud not found")
fi

# 13: macOS Defaults
LABELS+=("macOS Defaults")
DESCRIPTIONS+=("Key repeat, Finder tweaks, no smart quotes")
SELECTED+=(1)
_press_hold=$(defaults read -g ApplePressAndHoldEnabled 2>/dev/null || echo "1")
[ "$_press_hold" = "0" ] && STATUS+=("applied") || STATUS+=("")

_total=${#LABELS[@]}

# ========== Draw Menu ==========
draw_menu() {
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${CYAN}║           dotfiles installer — macOS             ║${NC}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  ${BOLD}Select components to install:${NC}"
  echo ""
  for (( i=0; i<_total; i++ )); do
    local _num; _num=$(printf "%2d" $((i + 1)))
    local _label; _label=$(printf "%-22s" "${LABELS[$i]}")
    local _status=""
    [ -n "${STATUS[$i]}" ] && _status=" ${GREEN}(${STATUS[$i]})${NC}"
    if [ "${SELECTED[$i]}" = "1" ]; then
      echo -e "    ${GREEN}${_num}. [x] ${_label}${NC} ${DIM}${DESCRIPTIONS[$i]}${NC}${_status}"
    else
      echo -e "    ${_num}. [ ] ${_label} ${DIM}${DESCRIPTIONS[$i]}${NC}${_status}"
    fi
  done
  echo ""
  echo -e "  ${DIM}Always included:${NC}"
  echo -e "    ${DIM}• Xcode CLT, Homebrew, Dotfiles repo${NC}"
  echo -e "    ${DIM}• Backup, Symlinks, Shell cleanup, Git config${NC}"
  echo ""
  echo -e "  ${DIM}Enter number to toggle  |  ${NC}${BOLD}a${NC}${DIM} = all  |  ${NC}${BOLD}n${NC}${DIM} = none  |  ${NC}${BOLD}Enter${NC}${DIM} = continue${NC}"
  echo ""
}

# ========== Interactive Loop ==========
while true; do
  clear 2>/dev/null || true
  draw_menu

  printf "  > "
  read -r _input < /dev/tty

  if [[ "$_input" =~ ^[0-9]+$ ]] && [ "$_input" -ge 1 ] && [ "$_input" -le "$_total" ]; then
    _idx=$((_input - 1))
    [ "${SELECTED[$_idx]}" = "1" ] && SELECTED[$_idx]=0 || SELECTED[$_idx]=1
  elif [[ "$_input" = [aA] ]]; then
    for (( i=0; i<_total; i++ )); do SELECTED[$i]=1; done
  elif [[ "$_input" = [nN] ]]; then
    for (( i=0; i<_total; i++ )); do SELECTED[$i]=0; done
  elif [ -z "$_input" ]; then
    break
  fi
  # Dependency: sui-move-analyzer (11) requires Rust (9)
  [ "${SELECTED[11]}" = "1" ] && SELECTED[9]=1
  # Deselect Rust (9) → auto-deselect sui-move-analyzer (11)
  [ "${SELECTED[9]}" = "0" ] && SELECTED[11]=0
done

# ========== Confirmation ==========
echo ""
echo -e "  ${BOLD}Will be installed:${NC}"
for (( i=0; i<_total; i++ )); do
  if [ "${SELECTED[$i]}" = "1" ]; then
    echo -e "    ${GREEN}+${NC} ${LABELS[$i]}  ${DIM}${DESCRIPTIONS[$i]}${NC}"
  fi
done
echo -e "    ${GREEN}+${NC} Xcode CLT, Homebrew, Dotfiles, Symlinks  ${DIM}(always)${NC}"
echo ""

printf "  ${BOLD}Proceed with installation?${NC} [y/n]: "
read -r _confirm < /dev/tty
case "$_confirm" in
  [yY]|[yY][eE][sS]) ;;
  *)
    echo -e "\n  ${YELLOW}⏭️  Installation cancelled.${NC}"
    exit 0
    ;;
esac

echo ""

# ══════════════════════════════════════════════════
#  ALWAYS: Core setup
# ══════════════════════════════════════════════════

# ========== Dotfiles Repo ==========
step "Checking dotfiles repository"
DOTFILES_DIR="$HOME/.dotfiles"
DOTFILES_REPO="https://github.com/rifuki/dotfiles.git"

_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$_script_dir/.git" ] && git -C "$_script_dir" rev-parse --git-dir > /dev/null 2>&1; then
  if [ "$_script_dir" != "$DOTFILES_DIR" ]; then
    fail_msg "install.sh must be run from $HOME/.dotfiles"
    echo -e "    ${DIM}Found at: $_script_dir${NC}"
    echo -e "    ${DIM}1. curl -fsSL https://dotfiles.rifuki.dev/macos/install.sh | bash${NC}"
    echo -e "    ${DIM}2. mv $_script_dir $DOTFILES_DIR && bash $DOTFILES_DIR/install.sh${NC}"
    exit 1
  fi
  done_msg "Running from: $DOTFILES_DIR"
else
  if [ ! -d "$DOTFILES_DIR/.git" ]; then
    info_msg "Cloning dotfiles repo..."
    git clone --branch macos "$DOTFILES_REPO" "$DOTFILES_DIR"
    done_msg "Cloned to $DOTFILES_DIR"
  else
    done_msg "Repo exists, pulling latest..."
    git -C "$DOTFILES_DIR" pull --ff-only 2>/dev/null || warn_msg "Could not pull"
  fi
fi

# ========== Backup ==========
step "Checking for existing configs"
BACKUP_DIR="$HOME/.config/backup-$(date +%Y%m%d-%H%M%S)"
_did_backup=0
for _d in "$DOTFILES_DIR/.config"/*/; do
  _name="$(basename "$_d")"
  _p="$HOME/.config/$_name"
  if [ -d "$_p" ] && [ ! -L "$_p" ]; then
    [ "$_did_backup" = "0" ] && mkdir -p "$BACKUP_DIR"
    mv "$_p" "$BACKUP_DIR/"
    _did_backup=1
  fi
done
for _f in "$HOME/.zshrc" "$HOME/.hyper.js"; do
  if [ -f "$_f" ] && [ ! -L "$_f" ]; then
    [ "$_did_backup" = "0" ] && mkdir -p "$BACKUP_DIR"
    mv "$_f" "$BACKUP_DIR/"
    _did_backup=1
  fi
done
[ "$_did_backup" = "1" ] && done_msg "Backed up to: $BACKUP_DIR" || done_msg "No existing configs to backup"

for _d in "$DOTFILES_DIR/.config"/*/; do
  _name="$(basename "$_d")"
  _p="$HOME/.config/$_name"
  if git -C "$DOTFILES_DIR" status --porcelain ".config/$_name" 2>/dev/null | grep -q .; then
    if [ -L "$_p" ] || [ -e "$_p" ]; then
      [ "$_did_backup" = "0" ] && mkdir -p "$BACKUP_DIR/.config"
      cp -rL "$_p" "$BACKUP_DIR/.config/" 2>/dev/null || true
      _did_backup=1
    fi
  fi
done
for _f in .zshrc .hyper.js; do
  if git -C "$DOTFILES_DIR" status --porcelain "$_f" 2>/dev/null | grep -q .; then
    if [ -L "$HOME/$_f" ] || [ -e "$HOME/$_f" ]; then
      [ "$_did_backup" = "0" ] && mkdir -p "$BACKUP_DIR"
      cp -rL "$HOME/$_f" "$BACKUP_DIR/" 2>/dev/null || true
      _did_backup=1
    fi
  fi
done
if [ "$_did_backup" = "1" ]; then
  done_msg "Local changes backed up"
  info_msg "Restoring to remote state..."
  git -C "$DOTFILES_DIR" restore . 2>/dev/null || git -C "$DOTFILES_DIR" checkout -- . 2>/dev/null || true
  git -C "$DOTFILES_DIR" clean -fd 2>/dev/null || true
  done_msg "Dotfiles restored"
fi

# ========== Homebrew ==========
step "Checking Homebrew"
if ! command -v brew &>/dev/null; then
  info_msg "Installing Homebrew..."
  set +e
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  BREW_RESULT=$?
  set -e
  if [ $BREW_RESULT -ne 0 ]; then
    fail_msg "Homebrew installation failed"
    echo -e "    ${DIM}Install manually, then re-run this script${NC}"
    exit 1
  fi
  eval "$(/opt/homebrew/bin/brew shellenv bash)"
  done_msg "Homebrew installed"
else
  done_msg "Homebrew already installed: $(brew --version | head -1)"
fi

# ══════════════════════════════════════════════════
#  SELECTED: Optional components
# ══════════════════════════════════════════════════

# ========== 0: Homebrew Formulae ==========
if [ "${SELECTED[0]}" = "1" ]; then
  step "Installing Homebrew formulae"
  _formulae=(
    "neovim:nvim"
    "tmux:tmux"
    "trash:trash"
    "htop:htop"
    "ripgrep:rg"
    "starship:starship"
    "neofetch:neofetch"
    "yazi:yazi"
    "gh:gh"
  )
  for _entry in "${_formulae[@]}"; do
    IFS=':' read -r _pkg _cmd <<< "$_entry"
    if ! command -v "$_cmd" &>/dev/null; then
      info_msg "Installing ${_pkg}..."
      brew install "$_pkg"
      done_msg "${_pkg} installed"
    else
      done_msg "${_pkg} already installed"
    fi
  done
fi

# ========== 1: Yabai + Skhd ==========
if [ "${SELECTED[1]}" = "1" ]; then
  step "Installing window manager"
  if ! command -v yabai &>/dev/null; then
    info_msg "Installing Yabai..."
    brew install asmvik/formulae/yabai
    done_msg "Yabai installed"
  else
    done_msg "Yabai already installed"
  fi
  if ! command -v skhd &>/dev/null; then
    info_msg "Installing Skhd..."
    brew install asmvik/formulae/skhd
    done_msg "Skhd installed"
  else
    done_msg "Skhd already installed"
  fi
fi

# ========== 2: Ghostty + Font ==========
if [ "${SELECTED[2]}" = "1" ]; then
  step "Installing Ghostty + Nerd Font"
  if [ ! -d "/Applications/Ghostty.app" ]; then
    info_msg "Installing Ghostty..."
    brew install --cask ghostty
    done_msg "Ghostty installed"
  else
    done_msg "Ghostty already installed"
  fi
  if ! brew list --cask font-jetbrains-mono-nerd-font &>/dev/null && \
     ! ls "$HOME/Library/Fonts/JetBrainsMono"*"NerdFont"* &>/dev/null 2>&1; then
    info_msg "Installing JetBrainsMono Nerd Font..."
    brew install --cask font-jetbrains-mono-nerd-font
    done_msg "JetBrainsMono Nerd Font installed"
  else
    done_msg "JetBrainsMono Nerd Font already installed"
  fi
fi

# ========== 3: Cloudflare WARP + Hot ==========
if [ "${SELECTED[3]}" = "1" ]; then
  step "Installing menu bar apps"
  if [ ! -d "/Applications/Cloudflare WARP.app" ]; then
    info_msg "Installing Cloudflare WARP..."
    brew install --cask cloudflare-warp
    done_msg "Cloudflare WARP installed"
  else
    done_msg "Cloudflare WARP already installed"
  fi
  if [ ! -d "/Applications/Hot.app" ]; then
    info_msg "Installing Hot..."
    brew install --cask hot
    done_msg "Hot installed"
  else
    done_msg "Hot already installed"
  fi
fi

# ========== 4: Google Chrome ==========
if [ "${SELECTED[4]}" = "1" ]; then
  step "Installing Google Chrome"
  if [ ! -d "/Applications/Google Chrome.app" ]; then
    info_msg "Installing Google Chrome..."
    brew install --cask google-chrome
    done_msg "Google Chrome installed"
  else
    done_msg "Google Chrome already installed"
  fi
fi

# ========== 5: OrbStack ==========
if [ "${SELECTED[5]}" = "1" ]; then
  step "Installing OrbStack"
  if [ ! -d "/Applications/OrbStack.app" ]; then
    info_msg "Installing OrbStack..."
    brew install --cask orbstack
    done_msg "OrbStack installed"
  else
    done_msg "OrbStack already installed"
  fi
fi

# ========== 6: Oh My Zsh ==========
if [ "${SELECTED[6]}" = "1" ]; then
  step "Setting up Oh My Zsh"
  if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    info_msg "Installing Oh My Zsh..."
    RUNZSH=no KEEP_ZSHRC=yes CHSH=no bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || {
      fail_msg "Oh My Zsh installation failed!"
      exit 1
    }
    done_msg "Oh My Zsh installed"
  else
    done_msg "Oh My Zsh already installed"
  fi
  ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
  info_msg "Checking plugins..."
  if [[ ! -f "$ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    rm -rf "$ZSH_CUSTOM/plugins/zsh-autosuggestions" 2>/dev/null || true
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  fi
  if [[ ! -f "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    rm -rf "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" 2>/dev/null || true
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  fi
  done_msg "Plugins ready"
fi

# ========== 7: NVM + Node ==========
if [ "${SELECTED[7]}" = "1" ]; then
  step "Setting up NVM + Node 24"
  export NVM_DIR="$HOME/.nvm"
  if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    info_msg "Installing NVM..."
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | PROFILE=/dev/null bash
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    done_msg "NVM installed"
  else
    done_msg "NVM already installed"
    \. "$NVM_DIR/nvm.sh"
  fi
  if ! nvm ls 24 &>/dev/null; then
    info_msg "Installing Node.js 24..."
    nvm install 24
    done_msg "Node.js 24 installed"
  else
    done_msg "Node.js 24 already installed"
  fi
  nvm use 24
fi

# ========== 8: Bun ==========
if [ "${SELECTED[8]}" = "1" ]; then
  step "Setting up Bun"
  if [ ! -f "$HOME/.bun/bin/bun" ]; then
    info_msg "Installing Bun..."
    curl -fsSL https://bun.sh/install | bash
    git -C "$DOTFILES_DIR" restore .zshrc 2>/dev/null || true
    done_msg "Bun installed"
  else
    done_msg "Bun already installed: $("$HOME/.bun/bin/bun" --version)"
  fi
fi

# ========== 9: Rust ==========
if [ "${SELECTED[9]}" = "1" ]; then
  step "Setting up Rust"
  if [ ! -f "$HOME/.cargo/bin/rustup" ]; then
    info_msg "Installing Rust (stable)..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --no-modify-path
    source "$HOME/.cargo/env"
    done_msg "Rust installed"
  else
    source "$HOME/.cargo/env" 2>/dev/null || true
    if ! "$HOME/.cargo/bin/rustup" show active-toolchain &>/dev/null; then
      info_msg "No default toolchain found, setting stable..."
      "$HOME/.cargo/bin/rustup" default stable
      done_msg "Rust stable toolchain set"
    else
      done_msg "Rust already installed: $("$HOME/.cargo/bin/rustc" --version)"
    fi
  fi
fi

# ========== 10: suiup + Sui Testnet ==========
if [ "${SELECTED[10]}" = "1" ]; then
  step "Installing suiup + Sui Testnet"
  if [ ! -f "$HOME/.local/bin/suiup" ]; then
    info_msg "Installing suiup..."
    curl -sSfL https://raw.githubusercontent.com/MystenLabs/suiup/main/install.sh | sh
    done_msg "suiup installed"
  else
    done_msg "suiup already installed"
  fi
  export PATH="$HOME/.local/bin:$PATH"
  if command -v suiup &>/dev/null; then
    if [ ! -f "$HOME/.local/bin/sui" ]; then
      info_msg "Installing Sui testnet (latest)..."
      suiup install sui@testnet
      done_msg "Sui testnet installed"
    else
      done_msg "Sui testnet already installed: $("$HOME/.local/bin/sui" --version 2>/dev/null | head -1)"
    fi
  else
    warn_msg "suiup not found in PATH — run: suiup install sui@testnet"
  fi
fi

# ========== 12: SSH Keys (iCloud) ==========
if [ "${SELECTED[12]}" = "1" ]; then
  step "Setting up SSH keys from iCloud"
  _icloud_base="$HOME/Library/Mobile Documents/com~apple~CloudDocs"

  if [ -L "$HOME/.ssh" ]; then
    done_msg "~/.ssh already symlinked → $(readlink "$HOME/.ssh")"
  else
    _ssh_path=""

    # Auto-detect .ssh in iCloud
    if [ -d "$_icloud_base" ]; then
      _ssh_results=()
      while IFS= read -r _line; do
        _ssh_results+=("$_line")
      done < <(find "$_icloud_base" -maxdepth 3 -type d -name ".ssh" 2>/dev/null)

      if [ ${#_ssh_results[@]} -eq 1 ]; then
        info_msg "Found .ssh at: ${_ssh_results[0]}"
        if confirm "Use this path?"; then
          _ssh_path="${_ssh_results[0]}"
        fi
      elif [ ${#_ssh_results[@]} -gt 1 ]; then
        info_msg "Found ${#_ssh_results[@]} .ssh folders in iCloud:"
        for (( _si=0; _si<${#_ssh_results[@]}; _si++ )); do
          echo -e "    ${BOLD}$((_si + 1)).${NC} ${_ssh_results[$_si]}"
        done
        printf "    Pick a number (or Enter to skip): "
        read -r _pick < /dev/tty
        if [[ "$_pick" =~ ^[0-9]+$ ]] && [ "$_pick" -ge 1 ] && [ "$_pick" -le ${#_ssh_results[@]} ]; then
          _ssh_path="${_ssh_results[$((_pick - 1))]}"
        fi
      fi
    fi

    # Manual input fallback
    if [ -z "$_ssh_path" ]; then
      printf "    Enter path to .ssh folder: "
      read -r _ssh_path < /dev/tty
      _ssh_path="${_ssh_path/#\~/$HOME}"
    fi

    # Validate and create symlink
    if [ -n "$_ssh_path" ] && [ -d "$_ssh_path" ]; then
      if [ -d "$HOME/.ssh" ]; then
        warn_msg "~/.ssh exists as a regular directory"
        if confirm "Backup and replace?"; then
          mv "$HOME/.ssh" "$HOME/.ssh.bak-$(date +%Y%m%d-%H%M%S)"
          done_msg "Backed up existing ~/.ssh"
        else
          warn_msg "Skipped SSH symlink"
          _ssh_path=""
        fi
      fi
      if [ -n "$_ssh_path" ]; then
        ln -sf "$_ssh_path" "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"

        # Fix SSH permissions
        find "$HOME/.ssh" -type f ! -name "*.pub" ! -name "known_hosts*" -exec chmod 600 {} \; 2>/dev/null || true
        find "$HOME/.ssh" -type f -name "*.pub" -exec chmod 644 {} \; 2>/dev/null || true

        done_msg "~/.ssh → $_ssh_path"
      fi
    elif [ -n "$_ssh_path" ]; then
      warn_msg "Path not found: $_ssh_path"
    fi
  fi
fi

# ========== 13: macOS Defaults ==========
if [ "${SELECTED[13]}" = "1" ]; then
  step "Applying macOS defaults"
  bash "$DOTFILES_DIR/macos-defaults.sh"
fi

# ══════════════════════════════════════════════════
#  ALWAYS: Finalize
# ══════════════════════════════════════════════════

# ========== Symlinks ==========
step "Setting up dotfiles symlinks"
_src="${BASH_SOURCE[0]:-}"
if [[ "$_src" == /* ]] && [[ -f "$_src" ]]; then
  REPO_DIR="$(cd "$(dirname "$_src")" && pwd)"
else
  REPO_DIR="$DOTFILES_DIR"
fi
for _d in "$REPO_DIR/.config"/*/; do
  rm -f "$HOME/.config/$(basename "$_d")"
done
rm -f "$HOME/.zshrc" "$HOME/.hyper.js"
mkdir -p "$HOME/.config"
for _d in "$REPO_DIR/.config"/*/; do
  _name="$(basename "$_d")"
  ln -sf "$REPO_DIR/.config/$_name" "$HOME/.config/$_name"
  done_msg "~/.config/$_name"
done
ln -sf "$REPO_DIR/.zshrc" "$HOME/.zshrc"
done_msg "~/.zshrc"
ln -sf "$REPO_DIR/.hyper.js" "$HOME/.hyper.js"
done_msg "~/.hyper.js"

# ========== Hush Login ==========
[ ! -f "$HOME/.hushlogin" ] && touch "$HOME/.hushlogin" && done_msg ".hushlogin created"

# ========== Shell Cleanup ==========
step "Cleaning up shell profiles"
for _f in "$HOME/.zprofile" "$HOME/.zshenv" "$HOME/.profile" "$HOME/.bash_profile" "$HOME/.bashrc"; do
  [ -f "$_f" ] || continue
  grep -qE 'cargo/env|NVM_DIR|nvm\.sh|bun\.sh|BUN_INSTALL|_bun' "$_f" 2>/dev/null || continue
  grep -vE 'cargo/env|NVM_DIR|nvm\.sh|bun\.sh|BUN_INSTALL|_bun|Added by.*installer' "$_f" > "${_f}.tmp" || true
  if [ -s "${_f}.tmp" ]; then
    mv "${_f}.tmp" "$_f"
  else
    rm -f "${_f}.tmp" "$_f"
  fi
  done_msg "Cleaned: $(basename "$_f")"
done
done_msg "Shell profiles clean"

# ========== Tmux Plugins ==========
if command -v tmux &>/dev/null; then
  step "Setting up Tmux plugins"
  TPM_DIR="$HOME/.config/tmux/plugins/tpm"
  if [ ! -d "$TPM_DIR" ]; then
    info_msg "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    done_msg "TPM installed"
  else
    done_msg "TPM already installed"
  fi
  if [ -x "$TPM_DIR/bin/install_plugins" ]; then
    "$TPM_DIR/bin/install_plugins"
    done_msg "Tmux plugins installed"
  else
    warn_msg "TPM install_plugins not found"
  fi
fi

# ========== Git Config ==========
step "Checking Git config"
GIT_NAME_SET=$(git config --global user.name 2>/dev/null || true)
GIT_EMAIL_SET=$(git config --global user.email 2>/dev/null || true)
if [ -z "$GIT_NAME_SET" ] || [ -z "$GIT_EMAIL_SET" ]; then
  if confirm "Configure Git user name and email?"; then
    printf "    Enter your Git name: " && read -r GIT_NAME < /dev/tty
    printf "    Enter your Git email: " && read -r GIT_EMAIL < /dev/tty
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
    done_msg "Git config set"
  else
    warn_msg "Git config skipped"
  fi
else
  done_msg "Git configured: $GIT_NAME_SET <$GIT_EMAIL_SET>"
fi

# ========== Default Shell ==========
if [ "$SHELL" != "$(which zsh)" ]; then
  step "Setting zsh as default shell"
  chsh -s "$(which zsh)" || warn_msg "chsh failed"
fi

# ========== 11: sui-move-analyzer ==========
if [ "${SELECTED[11]}" = "1" ]; then
  step "Checking sui-move-analyzer"
  if [ ! -f "$HOME/.cargo/bin/sui-move-analyzer" ]; then
    if command -v cargo &>/dev/null; then
      tmux kill-session -t sui-install 2>/dev/null || true
      info_msg "Spawning in tmux background session..."
      tmux new-session -d -s sui-install -n "sui-move-analyzer" \
        "cargo install --git https://github.com/movebit/sui-move-analyzer.git sui-move-analyzer; \
         echo ''; \
         echo '✅ sui-move-analyzer installed!'; \
         read -r _dummy"
      done_msg "Install started in background"
      echo -e "  ${DIM}Monitor:  tmux attach -t sui-install${NC}"
      echo -e "  ${DIM}Detach:   Ctrl+b then d${NC}"
    else
      warn_msg "Rust not installed, skipping sui-move-analyzer"
    fi
  else
    done_msg "sui-move-analyzer already installed"
  fi
fi

# ========== Done ==========
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║           ✓ Installation complete!               ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
if [ "${SELECTED[1]}" = "1" ]; then
  echo -e "  ${CYAN}Yabai:${NC}"
  echo -e "    ${DIM}1. echo \"\$(whoami) ALL=(root) NOPASSWD: sha256:\$(shasum -a 256 \$(which yabai) | cut -d \" \" -f 1) \$(which yabai) --load-sa\" | sudo tee /private/etc/sudoers.d/yabai${NC}"
  echo -e "    ${DIM}2. yabai --start-service${NC}"
  echo -e "    ${DIM}3. Allow in System Settings > Privacy & Security > Accessibility${NC}"
  echo ""
  echo -e "  ${CYAN}Skhd:${NC}"
  echo -e "    ${DIM}1. skhd --start-service${NC}"
  echo -e "    ${DIM}2. Allow in System Settings > Privacy & Security > Accessibility${NC}"
  echo ""
fi
echo -e "  ${DIM}👉 Restart your terminal or run: exec zsh${NC}"
echo ""
