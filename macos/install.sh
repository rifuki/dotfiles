#!/bin/bash
set -e

# ========== Colors (Miku Cyberpunk Theme) ==========
# Cyan: #00D9FF | Green: #50FA7B | Magenta: #FF79C6 | Purple: #BD93F9
# Teal: #01CBC6 | Orange: #FFB86C | Peach: #F0CAA4 | Gray: #6C757D
CYAN='\033[38;2;0;217;255m'
GREEN='\033[38;2;80;250;123m'
MAGENTA='\033[38;2;255;121;198m'
PURPLE='\033[38;2;189;147;249m'
TEAL='\033[38;2;1;203;198m'
ORANGE='\033[38;2;255;184;108m'
PEACH='\033[38;2;240;202;164m'
GRAY='\033[38;2;108;117;125m'
RED='\033[38;2;255;85;85m'
YELLOW='\033[38;2;241;250;140m'
WHITE='\033[38;2;239;241;244m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ========== Helpers ==========
step()     { echo -e "\n${BOLD}${CYAN}  ◆ $1${NC}"; }
done_msg() { echo -e "  ${GREEN}✔${NC} $1"; }
info_msg() { echo -e "  ${CYAN}▸${NC} $1"; }
warn_msg() { echo -e "  ${PEACH}▸${NC} $1"; }
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

# ========== Rosetta 2 (Apple Silicon only) ==========
if [[ "$(uname -m)" == "arm64" ]]; then
  step "Checking Rosetta 2"
  if /usr/bin/pgrep -q oahd; then
    done_msg "Rosetta 2 already installed"
  else
    info_msg "Installing Rosetta 2..."
    softwareupdate --install-rosetta --agree-to-license
    done_msg "Rosetta 2 installed"
  fi
fi

echo ""

# ========== Detect Current State ==========
LABELS=()
DESCRIPTIONS=()
SELECTED=()
STATUS=()
EXTERNAL=()   # 1 = found but not installed by this script — cannot manage

# 0: Homebrew Formulae + Nerd Font
LABELS+=("Homebrew Formulae + Nerd Font")
DESCRIPTIONS+=("neovim, tmux, trash, htop, ripgrep, starship, neofetch, yazi, fzf, gh, imagemagick, JetBrainsMono")
_fi=0
for _cmd in nvim tmux trash htop rg starship neofetch yazi fzf gh magick; do
  command -v "$_cmd" &>/dev/null && ((_fi++)) || true
done
if brew list --cask font-jetbrains-mono-nerd-font &>/dev/null || ls "$HOME/Library/Fonts/JetBrainsMono"*"NerdFont"* &>/dev/null 2>&1; then
  ((_fi++))
fi
if [ "$_fi" -eq 12 ]; then STATUS+=("all installed"); SELECTED+=(0)
elif [ "$_fi" -gt 0 ]; then STATUS+=("${_fi}/12 installed"); SELECTED+=(1)
else STATUS+=(""); SELECTED+=(1); fi
EXTERNAL+=(0)

# 1: Yabai + Skhd — install.sh installs via brew
LABELS+=("Yabai + Skhd")
DESCRIPTIONS+=("Tiling WM + hotkey daemon")
if brew list yabai &>/dev/null 2>&1 || brew list skhd &>/dev/null 2>&1; then
  STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0)
elif command -v yabai &>/dev/null || command -v skhd &>/dev/null; then
  STATUS+=("installed (external)"); SELECTED+=(0); EXTERNAL+=(1)
else
  STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0)
fi

# 2: Ghostty — install.sh installs via brew cask
LABELS+=("Ghostty")
DESCRIPTIONS+=("Ghostty terminal")
if brew list --cask ghostty &>/dev/null 2>&1; then
  STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0)
elif [ -d "/Applications/Ghostty.app" ]; then
  STATUS+=("installed (external)"); SELECTED+=(0); EXTERNAL+=(1)
else
  STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0)
fi

# 3: Cloudflare WARP + Hot — install.sh installs via brew cask
LABELS+=("Cloudflare WARP + Hot")
DESCRIPTIONS+=("Menu bar: VPN + thermal monitor")
_warp_brew=0; _hot_brew=0
brew list --cask cloudflare-warp &>/dev/null 2>&1 && _warp_brew=1 || true
brew list --cask hot &>/dev/null 2>&1 && _hot_brew=1 || true
_warp_found=0; _hot_found=0
[ -d "/Applications/Cloudflare WARP.app" ] && _warp_found=1
[ -d "/Applications/Hot.app" ] && _hot_found=1
if [ "$_warp_found" = "1" ] || [ "$_hot_found" = "1" ]; then
  _cf_ext=0
  [ "$_warp_found" = "1" ] && [ "$_warp_brew" = "0" ] && _cf_ext=1
  [ "$_hot_found" = "1" ] && [ "$_hot_brew" = "0" ] && _cf_ext=1
  if [ "$_cf_ext" = "1" ]; then
    STATUS+=("installed (external)"); SELECTED+=(0); EXTERNAL+=(1)
  else
    STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0)
  fi
else
  STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0)
fi

# 4: Google Chrome — check if managed by brew cask
LABELS+=("Google Chrome")
DESCRIPTIONS+=("Browser")
if brew list --cask google-chrome &>/dev/null 2>&1; then
  STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0)
elif [ -d "/Applications/Google Chrome.app" ]; then
  STATUS+=("installed (external)"); SELECTED+=(0); EXTERNAL+=(1)
else
  STATUS+=(""); SELECTED+=(0); EXTERNAL+=(0)
fi

# 5: OrbStack — check if managed by brew cask
LABELS+=("OrbStack")
DESCRIPTIONS+=("Docker & Linux VM runtime")
if brew list --cask orbstack &>/dev/null 2>&1; then
  STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0)
elif [ -d "/Applications/OrbStack.app" ]; then
  STATUS+=("installed (external)"); SELECTED+=(0); EXTERNAL+=(1)
else
  STATUS+=(""); SELECTED+=(0); EXTERNAL+=(0)
fi

# 6: mise
LABELS+=("Mise")
DESCRIPTIONS+=("Polyglot version manager (foundry, node, etc)")
if command -v mise &>/dev/null; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0)
else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

# 7: Oh My Zsh
LABELS+=("Oh My Zsh")
DESCRIPTIONS+=("Zsh framework + plugins")
if [ -d "$HOME/.oh-my-zsh" ]; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0); else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

# 7: Rust
LABELS+=("Rust")
DESCRIPTIONS+=("Rust toolchain via rustup")
if [ -f "$HOME/.cargo/bin/rustup" ]; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0); else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

# 8: Bun
LABELS+=("Bun")
DESCRIPTIONS+=("JavaScript runtime")
if [ -d "$HOME/.bun" ]; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0); else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

# 9: Node (Homebrew)
LABELS+=("Node (Homebrew)")
DESCRIPTIONS+=("Node.js via Homebrew — system default, managed per-project by mise")
if brew list node &>/dev/null 2>&1; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0); else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

# 10: Solana + AVM
LABELS+=("Solana + AVM")
DESCRIPTIONS+=("Solana CLI + Anchor Version Manager")
if command -v solana &>/dev/null || [ -f "$HOME/.local/share/solana/install/active_release/bin/solana" ]; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0); else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

# 11: suiup + Sui Testnet
LABELS+=("Suiup + Sui Testnet")
DESCRIPTIONS+=("Sui version manager + latest testnet binary")
if [ -f "$HOME/.local/bin/suiup" ]; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0); else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

# 12: sui-move-analyzer
LABELS+=("sui-move-analyzer")
DESCRIPTIONS+=("Sui Move language server (~10min)")
if [ -f "$HOME/.cargo/bin/sui-move-analyzer" ]; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0); else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

# 13: AI CLI Tools
LABELS+=("AI CLI Tools")
DESCRIPTIONS+=("Claude Code, Gemini CLI, Kimi CLI, OpenCode, Antigravity")
_ai_count=0
command -v claude &>/dev/null && ((_ai_count++)) || true
command -v gemini &>/dev/null && ((_ai_count++)) || true
command -v kimi &>/dev/null && ((_ai_count++)) || true
command -v opencode &>/dev/null && ((_ai_count++)) || true
[ -d "/Applications/Antigravity Tools.app" ] && ((_ai_count++)) || true
if [ "$_ai_count" -eq 5 ]; then STATUS+=("all installed"); SELECTED+=(0); EXTERNAL+=(0)
elif [ "$_ai_count" -gt 0 ]; then STATUS+=("${_ai_count}/5 installed"); SELECTED+=(1); EXTERNAL+=(0)
else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

# 14: SSH Keys (iCloud)
LABELS+=("SSH Keys (iCloud)")
DESCRIPTIONS+=("Symlink ~/.ssh → iCloud/rifuki/.ssh")
_icloud_base="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
_ssh_target="$_icloud_base/rifuki/.ssh"
if [ -L "$HOME/.ssh" ] && { [ -f "$HOME/.ssh/config" ] || ls "$HOME/.ssh"/*.pub &>/dev/null 2>&1; }; then
  SELECTED+=(0); STATUS+=("symlinked + configured"); EXTERNAL+=(0)
elif [ -L "$HOME/.ssh" ]; then
  SELECTED+=(1); STATUS+=("symlinked (empty)"); EXTERNAL+=(0)
elif [ -d "$_ssh_target" ]; then
  SELECTED+=(1); STATUS+=("iCloud/rifuki/.ssh found"); EXTERNAL+=(0)
elif [ -d "$_icloud_base" ]; then
  SELECTED+=(1); STATUS+=("iCloud available, path not found"); EXTERNAL+=(0)
else
  SELECTED+=(0); STATUS+=("iCloud not found"); EXTERNAL+=(0)
fi

# 15: macOS Defaults
LABELS+=("macOS Defaults")
DESCRIPTIONS+=("Key repeat, Finder tweaks, no smart quotes")
_md_result=$(bash "$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/macos-defaults-check.sh" 2>/dev/null) && _md_ok=1 || _md_ok=0
if [ "$_md_ok" = "1" ]; then STATUS+=("all applied"); SELECTED+=(0); EXTERNAL+=(0)
elif [ -n "$_md_result" ] && [ "${_md_result%%/*}" -gt 0 ] 2>/dev/null; then STATUS+=("${_md_result} applied"); SELECTED+=(1); EXTERNAL+=(0)
else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

_total=${#LABELS[@]}

# ========== Draw Menu ==========
draw_menu() {
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${CYAN}║           dotfiles installer — macOS             ║${NC}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════╝${NC}"
  echo ""
  # Check if all non-EXTERNAL items are unchecked (everything installed by script)
  local _all_unchecked=1
  for (( i=0; i<_total; i++ )); do
    [ "${EXTERNAL[$i]}" = "0" ] && [ "${SELECTED[$i]}" = "1" ] && _all_unchecked=0 && break
  done
  if [ "$_all_unchecked" = "1" ]; then
    echo -e "  ${BOLD}${GREEN}All components are already installed!${NC}"
    echo ""
  fi
  echo -e "  ${BOLD}${CYAN}Select components to install:${NC}"
  echo ""
  for (( i=0; i<_total; i++ )); do
    local _num; _num=$(printf "%2d" $((i + 1)))
    local _label; _label=$(printf "%-22s" "${LABELS[$i]}")
    local _status=""
    [ -n "${STATUS[$i]}" ] && _status=" ${TEAL}(${STATUS[$i]})${NC}"
    if [ "${EXTERNAL[$i]}" = "1" ]; then
      echo -e "    ${ORANGE}${_num}. [!] ${_label}${NC} ${DIM}not installed by this script — manage manually${NC}${_status}"
    elif [ "${SELECTED[$i]}" = "1" ]; then
      echo -e "    ${CYAN}${_num}. [x] ${_label}${NC} ${DIM}${DESCRIPTIONS[$i]}${NC}${_status}"
    else
      echo -e "    ${GRAY}${_num}. [ ] ${_label}${NC} ${DIM}${DESCRIPTIONS[$i]}${NC}${_status}"
    fi
  done
  echo ""
  echo -e "  ${GRAY}Always included:${NC}"
  echo -e "    ${DIM}• Xcode CLT, Homebrew, Dotfiles repo${NC}"
  echo -e "    ${DIM}• Backup, Symlinks, Shell cleanup, Git config${NC}"
  echo ""
  echo -e "  Enter number to toggle  |  ${BOLD}${CYAN}a${NC} = all  |  ${BOLD}${CYAN}n${NC} = none  |  ${BOLD}${CYAN}Enter${NC} = continue  |  ${BOLD}${CYAN}q${NC} = quit"
  echo ""
}

# ========== Interactive Loop ==========
while true; do
  draw_menu

  printf "  > "
  read -r _input < /dev/tty

  if [[ "$_input" =~ ^[0-9]+$ ]] && [ "$_input" -ge 1 ] && [ "$_input" -le "$_total" ]; then
    _idx=$((_input - 1))
    if [ "${EXTERNAL[$_idx]}" = "1" ]; then
      echo -e "  ${ORANGE}⚠  Not installed by this script — manage manually.${NC}"
      sleep 1.5
    else
      [ "${SELECTED[$_idx]}" = "1" ] && SELECTED[$_idx]=0 || SELECTED[$_idx]=1
    fi
  elif [[ "$_input" = [aA] ]]; then
    for (( i=0; i<_total; i++ )); do [ "${EXTERNAL[$i]}" != "1" ] && SELECTED[$i]=1; done
  elif [[ "$_input" = [nN] ]]; then
    for (( i=0; i<_total; i++ )); do SELECTED[$i]=0; done
  elif [ -z "$_input" ]; then
    break
  elif [[ "$_input" = [qQ] ]]; then
    echo -e "\n  ${YELLOW}⏭️  Installation cancelled.${NC}"
    exit 0
  fi
  # Dependency: Solana + AVM (11) requires Rust (8)
  [ "${SELECTED[11]}" = "1" ] && SELECTED[8]=1
  # Dependency: sui-move-analyzer (13) requires Rust (8)
  [ "${SELECTED[13]}" = "1" ] && SELECTED[8]=1
  # Dependency: AI CLI Tools (13) includes Copilot CLI which requires gh (part of 0)
  [ "${SELECTED[13]}" = "1" ] && SELECTED[0]=1
  # Deselect Rust (8) → auto-deselect Solana AVM (11) and sui-move-analyzer (13)
  [ "${SELECTED[8]}" = "0" ] && SELECTED[11]=0
  [ "${SELECTED[8]}" = "0" ] && SELECTED[13]=0
done

# ========== Confirmation ==========
echo ""
echo -e "  ${BOLD}${GREEN}Will be installed:${NC}"
for (( i=0; i<_total; i++ )); do
  if [ "${SELECTED[$i]}" = "1" ]; then
    echo -e "    ${CYAN}+${NC} ${LABELS[$i]}  ${DIM}${DESCRIPTIONS[$i]}${NC}"
  fi
done
echo -e "    ${CYAN}+${NC} Xcode CLT, Homebrew, Dotfiles, Symlinks  ${DIM}(always)${NC}"
echo ""

printf "  ${BOLD}${CYAN}Proceed with installation?${NC} ${GRAY}[y/n]:${NC} "
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

# ========== Dotfiles Paths ==========
DOTFILES_DIR="$HOME/.dotfiles"
SHARED_DIR="$DOTFILES_DIR/shared"
PLATFORM_DIR="$DOTFILES_DIR/macos"

# ========== Backup ==========
step "Checking for existing configs"
BACKUP_DIR="$HOME/.config/backup-$(date +%Y%m%d-%H%M%S)"
_did_backup=0
for _d in "$SHARED_DIR/.config"/*/ "$PLATFORM_DIR/.config"/*/; do
  [ -d "$_d" ] || continue
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

for _d in "$SHARED_DIR/.config"/*/ "$PLATFORM_DIR/.config"/*/; do
  [ -d "$_d" ] || continue
  _name="$(basename "$_d")"
  _p="$HOME/.config/$_name"
  _rel="${_d#"$DOTFILES_DIR/"}"
  if git -C "$DOTFILES_DIR" status --porcelain "$_rel" 2>/dev/null | grep -q .; then
    if [ -L "$_p" ] || [ -e "$_p" ]; then
      [ "$_did_backup" = "0" ] && mkdir -p "$BACKUP_DIR/.config"
      cp -rL "$_p" "$BACKUP_DIR/.config/" 2>/dev/null || true
      _did_backup=1
    fi
  fi
done
for _f in macos/.zshrc macos/.hyper.js; do
  if git -C "$DOTFILES_DIR" status --porcelain "$_f" 2>/dev/null | grep -q .; then
    _basename="$(basename "$_f")"
    if [ -L "$HOME/$_basename" ] || [ -e "$HOME/$_basename" ]; then
      [ "$_did_backup" = "0" ] && mkdir -p "$BACKUP_DIR"
      cp -rL "$HOME/$_basename" "$BACKUP_DIR/" 2>/dev/null || true
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

# ========== 0: Homebrew Formulae + Nerd Font ==========
if [ "${SELECTED[0]}" = "1" ]; then
  step "Installing Homebrew formulae + Nerd Font"
  _formulae=(
    "neovim:nvim"
    "tmux:tmux"
    "trash:trash"
    "htop:htop"
    "ripgrep:rg"
    "starship:starship"
    "neofetch:neofetch"
    "yazi:yazi"
    "fzf:fzf"
    "gh:gh"
    "imagemagick:magick"
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
  if ! brew list --cask font-jetbrains-mono-nerd-font &>/dev/null && \
     ! ls "$HOME/Library/Fonts/JetBrainsMono"*"NerdFont"* &>/dev/null 2>&1; then
    info_msg "Installing JetBrainsMono Nerd Font..."
    brew install --cask font-jetbrains-mono-nerd-font
    done_msg "JetBrainsMono Nerd Font installed"
  else
    done_msg "JetBrainsMono Nerd Font already installed"
  fi
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

# ========== 2: Ghostty ==========
if [ "${SELECTED[2]}" = "1" ]; then
  step "Installing Ghostty"
  if [ ! -d "/Applications/Ghostty.app" ]; then
    info_msg "Installing Ghostty..."
    brew install --cask ghostty
    done_msg "Ghostty installed"
  else
    done_msg "Ghostty already installed"
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

# ========== 6: mise ==========
if [ "${SELECTED[6]}" = "1" ]; then
  step "Installing mise"
  if ! command -v mise &>/dev/null; then
    info_msg "Installing mise..."
    brew install mise
    done_msg "mise installed: $(mise --version 2>/dev/null)"
  else
    done_msg "mise already installed: $(mise --version 2>/dev/null)"
  fi
fi

# ========== 7: Oh My Zsh ==========
if [ "${SELECTED[7]}" = "1" ]; then
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

# ========== 8: Rust ==========
if [ "${SELECTED[8]}" = "1" ]; then
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
    if ! "$HOME/.cargo/bin/rustup" component list --installed 2>/dev/null | grep -q "^rust-analyzer"; then
      info_msg "Installing rust-analyzer component..."
      "$HOME/.cargo/bin/rustup" component add rust-analyzer
      done_msg "rust-analyzer installed"
    fi
  fi
fi

# ========== 9: Bun ==========
if [ "${SELECTED[9]}" = "1" ]; then
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

# ========== 10: Node (Homebrew) ==========
if [ "${SELECTED[10]}" = "1" ]; then
  step "Setting up Node.js via Homebrew"
  if ! brew list node &>/dev/null 2>&1; then
    info_msg "Installing Node.js..."
    brew install node
    done_msg "Node.js installed: $(node --version 2>/dev/null)"
  else
    done_msg "Node.js already installed: $(node --version 2>/dev/null)"
  fi
fi

# ========== 11: Solana + AVM ==========
if [ "${SELECTED[11]}" = "1" ]; then
  step "Installing Solana + AVM"
  _solana_bin="$HOME/.local/share/solana/install/active_release/bin"
  if [ ! -f "$_solana_bin/solana" ]; then
    info_msg "Installing Solana CLI..."
    sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"
    done_msg "Solana CLI installed: $("$_solana_bin/solana" --version 2>/dev/null | head -1)"
  else
    done_msg "Solana CLI already installed: $("$_solana_bin/solana" --version 2>/dev/null | head -1)"
  fi
  export PATH="$_solana_bin:$PATH"
  if command -v cargo &>/dev/null; then
    if ! command -v avm &>/dev/null; then
      info_msg "Installing AVM (Anchor Version Manager)..."
      cargo install --git https://github.com/coral-xyz/anchor avm --locked --force
      done_msg "AVM installed"
    else
      done_msg "AVM already installed"
    fi
    if ! command -v anchor &>/dev/null; then
      info_msg "Installing Anchor (latest)..."
      avm install latest
      avm use latest
      done_msg "Anchor installed: $(anchor --version 2>/dev/null)"
    else
      done_msg "Anchor already installed: $(anchor --version 2>/dev/null)"
    fi
  else
    warn_msg "Rust not installed, skipping AVM + Anchor"
  fi
fi

# ========== 12: suiup + Sui Testnet ==========
if [ "${SELECTED[12]}" = "1" ]; then
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
      suiup install --yes sui@testnet
      done_msg "Sui testnet installed"
    else
      done_msg "Sui testnet already installed: $("$HOME/.local/bin/sui" --version 2>/dev/null | head -1)"
    fi
  else
    warn_msg "suiup not found in PATH — run: suiup install sui@testnet"
  fi
fi

# ========== 14: AI CLI Tools ==========
if [ "${SELECTED[14]}" = "1" ]; then
  step "Installing AI CLI Tools"
  if ! command -v claude &>/dev/null; then
    info_msg "Installing Claude Code..."
    brew install --cask claude-code
    done_msg "Claude Code installed"
  else
    done_msg "Claude Code already installed"
  fi
  if ! command -v gemini &>/dev/null; then
    info_msg "Installing Gemini CLI..."
    brew install gemini-cli
    done_msg "Gemini CLI installed"
  else
    done_msg "Gemini CLI already installed"
  fi
  if ! command -v kimi &>/dev/null; then
    info_msg "Installing Kimi CLI..."
    brew install kimi-cli
    done_msg "Kimi CLI installed"
  else
    done_msg "Kimi CLI already installed"
  fi
  if ! command -v opencode &>/dev/null; then
    info_msg "Installing OpenCode..."
    brew install opencode
    done_msg "OpenCode installed"
  else
    done_msg "OpenCode already installed"
  fi
  if [ ! -d "/Applications/Antigravity Tools.app" ]; then
    info_msg "Installing Antigravity..."
    brew install --cask antigravity
    done_msg "Antigravity installed"
  else
    done_msg "Antigravity already installed"
  fi
  # Claude config
  mkdir -p "$HOME/.claude"
  if [ -f "$SHARED_DIR/.claude/statusline-command.sh" ]; then
    ln -sf "$SHARED_DIR/.claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
    done_msg "~/.claude/statusline-command.sh"
  fi
  if [ -f "$SHARED_DIR/.claude/settings.json" ]; then
    ln -sf "$SHARED_DIR/.claude/settings.json" "$HOME/.claude/settings.json"
    done_msg "~/.claude/settings.json"
  fi
  # AI tools shell config
  if [ -f "$PLATFORM_DIR/ai-tools.sh" ]; then
    ln -sf "$PLATFORM_DIR/ai-tools.sh" "$HOME/.claude/ai-tools.sh"
    done_msg "~/.claude/ai-tools.sh → macos/ai-tools.sh"
  fi
  # GitHub Copilot CLI (try cask first, fallback to formula)
  if ! brew list --cask copilot-cli &>/dev/null 2>&1 && \
     ! brew list github-copilot &>/dev/null 2>&1 && \
     ! (command -v gh &>/dev/null && gh extension list 2>/dev/null | grep -q "github.com/github/copilot"); then
    info_msg "Installing GitHub Copilot CLI..."
    # Try cask first (official), fallback to formula if fails
    if brew install --cask copilot-cli 2>/dev/null; then
      done_msg "GitHub Copilot CLI installed (cask)"
    else
      warn_msg "Cask install failed, trying formula..."
      if brew install github-copilot 2>/dev/null; then
        done_msg "GitHub Copilot CLI installed (formula)"
      else
        warn_msg "Both cask and formula failed — install manually: brew install --cask copilot-cli"
      fi
    fi
  else
    done_msg "GitHub Copilot CLI already installed"
  fi
fi

# ========== 14: SSH Keys (iCloud) ==========
if [ "${SELECTED[14]}" = "1" ]; then
  step "Setting up SSH keys from iCloud"
  _icloud_base="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
  _ssh_target="$_icloud_base/rifuki/.ssh"

  if [ -L "$HOME/.ssh" ]; then
    done_msg "~/.ssh already symlinked → $(readlink "$HOME/.ssh")"
  else
    _ssh_path=""

    # Use fixed path: iCloud/rifuki/.ssh
    if [ -d "$_ssh_target" ]; then
      _ssh_path="$_ssh_target"
      info_msg "Found .ssh at: $_ssh_path"
    elif [ -d "$_icloud_base" ]; then
      # Fallback: manual input if rifuki/.ssh not found
      warn_msg "iCloud/rifuki/.ssh not found"
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
        ln -sfn "$_ssh_path" "$HOME/.ssh"
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

# ========== 15: macOS Defaults ==========
if [ "${SELECTED[15]}" = "1" ]; then
  step "Applying macOS defaults"
  bash "$PLATFORM_DIR/macos-defaults.sh"
fi

# ══════════════════════════════════════════════════
#  ALWAYS: Finalize
# ══════════════════════════════════════════════════

# ========== Symlinks ==========
step "Setting up dotfiles symlinks"

# Remove old symlinks
for _d in "$SHARED_DIR/.config"/*/ "$PLATFORM_DIR/.config"/*/; do
  [ -d "$_d" ] || continue
  rm -f "$HOME/.config/$(basename "$_d")"
done
rm -f "$HOME/.zshrc" "$HOME/.hyper.js"
mkdir -p "$HOME/.config"

# Symlink shared configs
for _d in "$SHARED_DIR/.config"/*/; do
  [ -d "$_d" ] || continue
  _name="$(basename "$_d")"
  ln -sf "$SHARED_DIR/.config/$_name" "$HOME/.config/$_name"
  done_msg "~/.config/$_name"
done

# Symlink platform configs (macOS-only apps, overrides shared if overlap)
for _d in "$PLATFORM_DIR/.config"/*/; do
  [ -d "$_d" ] || continue
  _name="$(basename "$_d")"
  ln -sf "$PLATFORM_DIR/.config/$_name" "$HOME/.config/$_name"
  done_msg "~/.config/$_name"
done

# Root dotfiles
ln -sf "$PLATFORM_DIR/.zshrc" "$HOME/.zshrc"
done_msg "~/.zshrc"
ln -sf "$PLATFORM_DIR/.hyper.js" "$HOME/.hyper.js"
done_msg "~/.hyper.js"

# ========== Hush Login ==========
[ ! -f "$HOME/.hushlogin" ] && touch "$HOME/.hushlogin" && done_msg ".hushlogin created"

# ========== Shell Cleanup ==========
step "Cleaning up shell profiles"
for _f in "$HOME/.zprofile" "$HOME/.zshenv" "$HOME/.profile" "$HOME/.bash_profile" "$HOME/.bashrc"; do
  [ -f "$_f" ] || continue
  grep -qE 'cargo/env|NVM_DIR|nvm\.sh|bun\.sh|BUN_INSTALL|_bun|solana/install' "$_f" 2>/dev/null || continue
  grep -vE 'cargo/env|NVM_DIR|nvm\.sh|bun\.sh|BUN_INSTALL|_bun|solana/install|Added by.*installer' "$_f" > "${_f}.tmp" || true
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

# ========== 13: sui-move-analyzer ==========
if [ "${SELECTED[13]}" = "1" ]; then
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
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║           ✓ Installation complete!               ║${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
if [ "${SELECTED[1]}" = "1" ]; then
  echo -e "  ${CYAN}Yabai:${NC}"
  echo -e "    ${DIM}1. echo \"\$(whoami) ALL=(root) NOPASSWD: sha256:\$(shasum -a 256 \$(which yabai) | cut -d \" \" -f 1) \$(which yabai) --load-sa\" | sudo tee /private/etc/sudoers.d/yabai${NC}"
  echo -e "    ${DIM}2. yabai --start-service${NC}"
  echo -e "    ${DIM}3. Allow in System Settings > Privacy & Security > Accessibility${NC}"
  echo ""
  echo -e "  ${PEACH}⚠  For full Yabai features, partial SIP disable is required (2 reboots):${NC}"
  if [[ "$(uname -m)" == "arm64" ]]; then
    echo -e "    ${DIM}1. Recovery Mode (hold power) → Utilities → Terminal:${NC}"
    echo -e "       ${DIM}csrutil enable --without fs --without debug --without nvram${NC}"
    echo -e "    ${DIM}   → Reboot${NC}"
    echo -e "    ${DIM}2. After reboot:  sudo nvram boot-args=-arm64e_preview_abi${NC}"
    echo -e "    ${DIM}   → Reboot again${NC}"
  else
    echo -e "    ${DIM}1. Recovery Mode (Cmd+R) → Utilities → Terminal:${NC}"
    echo -e "       ${DIM}csrutil disable --with kext --with dtrace --with nvram --with basesystem${NC}"
    echo -e "    ${DIM}   → Reboot${NC}"
  fi
  echo -e "    ${DIM}Guide: https://github.com/asmvik/yabai/wiki/Disabling-System-Integrity-Protection${NC}"
  echo ""
  echo -e "  ${CYAN}Skhd:${NC}"
  echo -e "    ${DIM}1. skhd --start-service${NC}"
  echo -e "    ${DIM}2. Allow in System Settings > Privacy & Security > Accessibility${NC}"
  echo ""
fi
echo -e "  ${CYAN}👉 Restart your terminal or run: exec zsh${NC}"
echo ""
