#!/bin/bash
set -e

# ========== Packages ==========
BREW_FORMULAE=(neovim tmux trash htop neofetch yazi gh ripgrep starship yabai skhd)
BREW_CASKS=(ghostty orbstack cloudflare-warp hot google-chrome font-jetbrains-mono-nerd-font)
TOOL_NAMES=(nvim starship ghostty yazi tmux neofetch wakatime orbstack yabai skhd sui gh ripgrep trash htop hot)

# ========== Colors ==========
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

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

# ========== Helpers ==========
step()     { echo -e "\n${BOLD}${CYAN}  ◆ $1${NC}"; }
done_msg() { echo -e "  ${GREEN}✔${NC} $1"; }
warn_msg() { echo -e "  ${YELLOW}▸${NC} $1"; }

# ========== Detect Installed Components ==========
LABELS=()
DESCRIPTIONS=()
SELECTED=()
DETECTED=()

# 0: Homebrew Packages
_brew_count=0
if command -v brew &>/dev/null; then
  for _pkg in "${BREW_FORMULAE[@]}"; do
    brew list "$_pkg" &>/dev/null && ((_brew_count++)) || true
  done
  for _pkg in "${BREW_CASKS[@]}"; do
    brew list --cask "$_pkg" &>/dev/null && ((_brew_count++)) || true
  done
fi
LABELS+=("Homebrew Packages")
DESCRIPTIONS+=("${_brew_count} packages found")
if [ "$_brew_count" -gt 0 ]; then
  DETECTED+=(1); SELECTED+=(1)
else
  DETECTED+=(0); SELECTED+=(0)
fi

# 1: NVM
LABELS+=("NVM")
DESCRIPTIONS+=("~/.nvm")
if [ -d "$HOME/.nvm" ]; then DETECTED+=(1); SELECTED+=(1); else DETECTED+=(0); SELECTED+=(0); fi

# 2: Bun
LABELS+=("Bun")
DESCRIPTIONS+=("~/.bun")
if [ -d "$HOME/.bun" ]; then DETECTED+=(1); SELECTED+=(1); else DETECTED+=(0); SELECTED+=(0); fi

# 3: Rust
LABELS+=("Rust")
DESCRIPTIONS+=("~/.cargo, ~/.rustup")
if [ -d "$HOME/.cargo" ] || [ -d "$HOME/.rustup" ]; then DETECTED+=(1); SELECTED+=(1); else DETECTED+=(0); SELECTED+=(0); fi

# 4: sui-move-analyzer
LABELS+=("sui-move-analyzer")
DESCRIPTIONS+=("~/.cargo/bin/sui-move-analyzer")
if [ -f "$HOME/.cargo/bin/sui-move-analyzer" ]; then DETECTED+=(1); SELECTED+=(1); else DETECTED+=(0); SELECTED+=(0); fi

# 5: Oh My Zsh
LABELS+=("Oh My Zsh")
DESCRIPTIONS+=("~/.oh-my-zsh")
if [ -d "$HOME/.oh-my-zsh" ]; then DETECTED+=(1); SELECTED+=(1); else DETECTED+=(0); SELECTED+=(0); fi

# 6: suiup + Sui
LABELS+=("suiup + Sui")
DESCRIPTIONS+=("~/.local/bin/sui*, ~/.sui")
if [ -f "$HOME/.local/bin/suiup" ] || [ -d "$HOME/.sui" ]; then DETECTED+=(1); SELECTED+=(1); else DETECTED+=(0); SELECTED+=(0); fi

# 7: Deep Clean
LABELS+=("Deep Clean")
DESCRIPTIONS+=(".cache, .local, .npm, .wakatime, .gitconfig")
DETECTED+=(1); SELECTED+=(1)

_total=${#LABELS[@]}

# ========== Draw Menu ==========
draw_menu() {
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${CYAN}║          dotfiles uninstaller — macOS            ║${NC}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  ${BOLD}Select components to remove:${NC}"
  echo ""
  for (( i=0; i<_total; i++ )); do
    local _num; _num=$(printf "%d" $((i + 1)))
    local _label; _label=$(printf "%-18s" "${LABELS[$i]}")
    if [ "${DETECTED[$i]}" = "0" ]; then
      echo -e "    ${DIM}${_num}. [ ] ${_label} —  not found${NC}"
    elif [ "${SELECTED[$i]}" = "1" ]; then
      echo -e "    ${GREEN}${_num}. [x] ${_label}${NC} ${DIM}${DESCRIPTIONS[$i]}${NC}"
    else
      echo -e "    ${_num}. [ ] ${_label} ${DIM}${DESCRIPTIONS[$i]}${NC}"
    fi
  done
  echo ""
  echo -e "  ${DIM}Always removed:${NC}"
  echo -e "    ${DIM}• Dotfiles symlinks (.zshrc, .hyper.js, .config/*)${NC}"
  echo -e "    ${DIM}• Cache files (.zcompdump, .node_repl_history)${NC}"
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
    if [ "${DETECTED[$_idx]}" = "1" ]; then
      [ "${SELECTED[$_idx]}" = "1" ] && SELECTED[$_idx]=0 || SELECTED[$_idx]=1
    fi
  elif [[ "$_input" = [aA] ]]; then
    for (( i=0; i<_total; i++ )); do
      [ "${DETECTED[$i]}" = "1" ] && SELECTED[$i]=1
    done
  elif [[ "$_input" = [nN] ]]; then
    for (( i=0; i<_total; i++ )); do
      SELECTED[$i]=0
    done
  elif [ -z "$_input" ]; then
    break
  fi
  # Dependency: Rust (3) selected → auto-select sui-move-analyzer (4) if detected
  [ "${SELECTED[3]}" = "1" ] && [ "${DETECTED[4]}" = "1" ] && SELECTED[4]=1
  # Deselect Rust (3) → auto-deselect sui-move-analyzer (4)
  [ "${SELECTED[3]}" = "0" ] && SELECTED[4]=0
done

# ========== Confirmation Summary ==========
echo ""
echo -e "  ${BOLD}Will be removed:${NC}"
for (( i=0; i<_total; i++ )); do
  if [ "${SELECTED[$i]}" = "1" ]; then
    echo -e "    ${RED}✗${NC} ${LABELS[$i]}  ${DIM}${DESCRIPTIONS[$i]}${NC}"
  fi
done
echo -e "    ${RED}✗${NC} Dotfiles symlinks"
echo -e "    ${RED}✗${NC} Cache files"
echo ""

printf "  ${BOLD}Proceed with uninstallation?${NC} [y/n]: "
read -r _confirm < /dev/tty
case "$_confirm" in
  [yY]|[yY][eE][sS]) ;;
  *)
    echo -e "\n  ${YELLOW}⏭️  Uninstallation cancelled.${NC}"
    exit 0
    ;;
esac

echo ""

# ========== Backup Current Configs ==========
DOTFILES_DIR="$HOME/.dotfiles"
UNINSTALL_BACKUP_DIR="$HOME/.config/backup-uninstall-$(date +%Y%m%d-%H%M%S)"
_did_backup=0

step "Creating backup of current configs"
for _d in "$DOTFILES_DIR/.config"/*/; do
  _name="$(basename "$_d")"
  _home_d="$HOME/.config/$_name"
  if [ -e "$_home_d" ]; then
    [ "$_did_backup" = "0" ] && mkdir -p "$UNINSTALL_BACKUP_DIR/.config"
    cp -rL "$_home_d" "$UNINSTALL_BACKUP_DIR/.config/" 2>/dev/null || true
    _did_backup=1
  fi
done
for _f in "$HOME/.zshrc" "$HOME/.hyper.js"; do
  if [ -e "$_f" ]; then
    [ "$_did_backup" = "0" ] && mkdir -p "$UNINSTALL_BACKUP_DIR"
    cp -L "$_f" "$UNINSTALL_BACKUP_DIR/" 2>/dev/null || true
    _did_backup=1
  fi
done
[ "$_did_backup" = "1" ] && done_msg "Backed up to: $UNINSTALL_BACKUP_DIR" || done_msg "No configs to backup"

# ========== Remove Symlinks (always) ==========
step "Removing dotfiles symlinks"
rm -f "$HOME/.zshrc"
rm -f "$HOME/.hyper.js"
for _d in "$HOME/.config"/*; do
  [ -L "$_d" ] && rm -f "$_d"
done
done_msg "Symlinks removed"

# ========== Homebrew Packages (index 0) ==========
if [ "${SELECTED[0]}" = "1" ]; then
  step "Removing Homebrew packages"
  for _pkg in "${BREW_FORMULAE[@]}"; do
    if brew list "$_pkg" &>/dev/null; then
      brew uninstall --ignore-dependencies "$_pkg" && done_msg "Removed $_pkg" || warn_msg "Failed to remove $_pkg"
    fi
  done
  for _pkg in "${BREW_CASKS[@]}"; do
    if brew list --cask "$_pkg" &>/dev/null; then
      brew uninstall --cask "$_pkg" && done_msg "Removed $_pkg" || warn_msg "Failed to remove $_pkg"
    fi
  done
  done_msg "Homebrew packages done"
fi

# ========== NVM (index 1) ==========
if [ "${SELECTED[1]}" = "1" ]; then
  step "Removing NVM"
  rm -rf "$HOME/.nvm"
  done_msg "NVM removed"
fi

# ========== Bun (index 2) ==========
if [ "${SELECTED[2]}" = "1" ]; then
  step "Removing Bun"
  rm -rf "$HOME/.bun"
  done_msg "Bun removed"
fi

# ========== Rust (index 3) ==========
if [ "${SELECTED[3]}" = "1" ]; then
  step "Removing Rust"
  rm -rf "$HOME/.cargo"
  rm -rf "$HOME/.rustup"
  done_msg "Rust removed"
fi

# ========== sui-move-analyzer (index 4) ==========
if [ "${SELECTED[4]}" = "1" ]; then
  step "Removing sui-move-analyzer"
  rm -f "$HOME/.cargo/bin/sui-move-analyzer"
  done_msg "sui-move-analyzer removed"
fi

# ========== Oh My Zsh (index 5) ==========
if [ "${SELECTED[5]}" = "1" ]; then
  step "Removing Oh My Zsh"
  rm -rf "$HOME/.oh-my-zsh"
  done_msg "Oh My Zsh removed"
fi

# ========== Cache Files (always) ==========
step "Cleaning up cache files"
rm -f "$HOME"/.zcompdump*
rm -f "$HOME/.node_repl_history"
rm -rf "$HOME/.config/github-copilot" 2>/dev/null || true
done_msg "Cache files removed"

# ========== suiup + Sui (index 6) ==========
if [ "${SELECTED[6]}" = "1" ]; then
  step "Removing suiup + Sui"
  rm -f "$HOME/.local/bin/suiup"
  done_msg "suiup removed"
  for _bin in sui walrus mvr; do
    [ -f "$HOME/.local/bin/$_bin" ] && rm -f "$HOME/.local/bin/$_bin" && done_msg "$_bin removed" || true
  done
  rm -rf "$HOME/.sui"
  done_msg "~/.sui removed"
fi

# ========== Deep Clean (index 7) ==========
if [ "${SELECTED[7]}" = "1" ]; then
  step "Deep cleaning residue files"

  # XDG directories
  for _dir in "$HOME/.cache" "$HOME/.local/share" "$HOME/.local/state"; do
    for _tool in "${TOOL_NAMES[@]}"; do
      if [ -e "$_dir/$_tool" ]; then
        rm -rf "$_dir/$_tool"
        done_msg "Removed $_dir/$_tool"
      fi
    done
  done

  # Tool config in .config
  rm -rf "$HOME/.config/gh"
  rm -rf "$HOME/.config/git"

  # Dotfiles in $HOME
  rm -f "$HOME/.zsh_history"
  rm -rf "$HOME/.zsh_sessions"
  rm -f "$HOME/.gitconfig"
  rm -f "$HOME/.gitignore_global"
  rm -f "$HOME/.hushlogin"
  rm -f "$HOME/.wakatime.cfg"
  rm -rf "$HOME/.wakatime"
  rm -rf "$HOME/.npm"
  rm -rf "$HOME/.orbstack"
  rm -f "$HOME/.viminfo"

  done_msg "Residue files removed"
fi

# ========== Done ==========
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║           ✓ Uninstallation complete!             ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
[ "$_did_backup" = "1" ] && echo -e "  ${CYAN}📦${NC} Backup: ${CYAN}$UNINSTALL_BACKUP_DIR${NC}"
echo -e "  ${DIM}👉 Restart your terminal or run: exec zsh${NC}"
echo ""
