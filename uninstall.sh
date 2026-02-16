#!/bin/bash
set -e

# ========== Packages ==========
BREW_FORMULAE=(neovim tmux trash htop neofetch yazi fzf gh ripgrep starship)
TOOL_NAMES=(nvim starship ghostty yazi tmux neofetch wakatime orbstack yabai skhd solana anchor claude gemini kimi opencode sui suiup walrus mvr gh ripgrep trash htop hot)

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
step()     { echo -e "\n${BOLD}${MAGENTA}  ◆ $1${NC}"; }
done_msg() { echo -e "  ${GREEN}✔${NC} $1"; }
warn_msg() { echo -e "  ${PEACH}▸${NC} $1"; }

# ========== Detect Installed Components ==========
LABELS=()
DESCRIPTIONS=()
SELECTED=()
DETECTED=()
EXTERNAL=()   # 1 = found but not installed by this script — cannot auto-remove

# 0: Homebrew Formulae + Nerd Font — detected via brew list (already brew-managed if found)
_brew_count=0
if command -v brew &>/dev/null; then
  for _pkg in "${BREW_FORMULAE[@]}"; do
    brew list "$_pkg" &>/dev/null && ((_brew_count++)) || true
  done
  if brew list --cask font-jetbrains-mono-nerd-font &>/dev/null; then
    ((_brew_count++))
  fi
fi
LABELS+=("Homebrew Formulae + Nerd Font")
DESCRIPTIONS+=("${_brew_count}/$((${#BREW_FORMULAE[@]} + 1)) found")
if [ "$_brew_count" -gt 0 ]; then
  DETECTED+=(1); SELECTED+=(1); EXTERNAL+=(0)
else
  DETECTED+=(0); SELECTED+=(0); EXTERNAL+=(0)
fi

# 1: Yabai + Skhd — install.sh installs via brew
LABELS+=("Yabai + Skhd")
DESCRIPTIONS+=("Tiling WM + hotkey daemon")
if brew list yabai &>/dev/null 2>&1 || brew list skhd &>/dev/null 2>&1; then
  DETECTED+=(1); SELECTED+=(0); EXTERNAL+=(0)
elif command -v yabai &>/dev/null || command -v skhd &>/dev/null; then
  DETECTED+=(1); SELECTED+=(0); EXTERNAL+=(1)
else
  DETECTED+=(0); SELECTED+=(0); EXTERNAL+=(0)
fi

# 2: Ghostty — install.sh installs via brew cask
LABELS+=("Ghostty")
DESCRIPTIONS+=("Ghostty terminal")
if brew list --cask ghostty &>/dev/null 2>&1; then
  DETECTED+=(1); SELECTED+=(1); EXTERNAL+=(0)
elif [ -d "/Applications/Ghostty.app" ]; then
  DETECTED+=(1); SELECTED+=(0); EXTERNAL+=(1)
else
  DETECTED+=(0); SELECTED+=(0); EXTERNAL+=(0)
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
  DETECTED+=(1)
  _cf_ext=0
  [ "$_warp_found" = "1" ] && [ "$_warp_brew" = "0" ] && _cf_ext=1
  [ "$_hot_found" = "1" ] && [ "$_hot_brew" = "0" ] && _cf_ext=1
  if [ "$_cf_ext" = "1" ]; then
    SELECTED+=(0); EXTERNAL+=(1)
  else
    SELECTED+=(1); EXTERNAL+=(0)
  fi
else
  DETECTED+=(0); SELECTED+=(0); EXTERNAL+=(0)
fi

# 4: Google Chrome — check if managed by brew cask
LABELS+=("Google Chrome")
DESCRIPTIONS+=("Browser")
if brew list --cask google-chrome &>/dev/null 2>&1; then
  DETECTED+=(1); SELECTED+=(0); EXTERNAL+=(0)
elif [ -d "/Applications/Google Chrome.app" ]; then
  DETECTED+=(1); SELECTED+=(0); EXTERNAL+=(1)
else
  DETECTED+=(0); SELECTED+=(0); EXTERNAL+=(0)
fi

# 5: OrbStack — check if managed by brew cask
LABELS+=("OrbStack")
DESCRIPTIONS+=("Docker & Linux VM runtime")
if brew list --cask orbstack &>/dev/null 2>&1; then
  DETECTED+=(1); SELECTED+=(0); EXTERNAL+=(0)
elif [ -d "/Applications/OrbStack.app" ]; then
  DETECTED+=(1); SELECTED+=(0); EXTERNAL+=(1)
else
  DETECTED+=(0); SELECTED+=(0); EXTERNAL+=(0)
fi

# 6: Oh My Zsh
LABELS+=("Oh My Zsh")
DESCRIPTIONS+=("~/.oh-my-zsh")
if [ -d "$HOME/.oh-my-zsh" ]; then DETECTED+=(1); SELECTED+=(1); EXTERNAL+=(0); else DETECTED+=(0); SELECTED+=(0); EXTERNAL+=(0); fi

# 7: Rust
LABELS+=("Rust")
DESCRIPTIONS+=("~/.cargo, ~/.rustup")
if [ -d "$HOME/.cargo" ] || [ -d "$HOME/.rustup" ]; then DETECTED+=(1); SELECTED+=(1); EXTERNAL+=(0); else DETECTED+=(0); SELECTED+=(0); EXTERNAL+=(0); fi

# 8: Bun
LABELS+=("Bun")
DESCRIPTIONS+=("~/.bun")
if [ -d "$HOME/.bun" ]; then DETECTED+=(1); SELECTED+=(1); EXTERNAL+=(0); else DETECTED+=(0); SELECTED+=(0); EXTERNAL+=(0); fi

# 9: NVM
LABELS+=("NVM")
DESCRIPTIONS+=("~/.nvm")
if [ -d "$HOME/.nvm" ]; then DETECTED+=(1); SELECTED+=(1); EXTERNAL+=(0); else DETECTED+=(0); SELECTED+=(0); EXTERNAL+=(0); fi

# 10: Solana + AVM
LABELS+=("Solana + AVM")
DESCRIPTIONS+=("~/.local/share/solana, ~/.avm")
if command -v solana &>/dev/null || [ -d "$HOME/.local/share/solana" ]; then DETECTED+=(1); SELECTED+=(1); EXTERNAL+=(0); else DETECTED+=(0); SELECTED+=(0); EXTERNAL+=(0); fi

# 11: suiup + Sui
LABELS+=("suiup + Sui")
DESCRIPTIONS+=("~/.local/bin/sui*, ~/.sui")
if [ -f "$HOME/.local/bin/suiup" ] || [ -d "$HOME/.sui" ]; then DETECTED+=(1); SELECTED+=(1); EXTERNAL+=(0); else DETECTED+=(0); SELECTED+=(0); EXTERNAL+=(0); fi

# 12: sui-move-analyzer
LABELS+=("sui-move-analyzer")
DESCRIPTIONS+=("~/.cargo/bin/sui-move-analyzer")
if [ -f "$HOME/.cargo/bin/sui-move-analyzer" ]; then DETECTED+=(1); SELECTED+=(1); EXTERNAL+=(0); else DETECTED+=(0); SELECTED+=(0); EXTERNAL+=(0); fi

# 13: AI CLI Tools
LABELS+=("AI CLI Tools")
DESCRIPTIONS+=("Claude Code, Gemini CLI, Kimi CLI, OpenCode")
if command -v claude &>/dev/null || command -v gemini &>/dev/null || command -v kimi &>/dev/null || command -v opencode &>/dev/null; then DETECTED+=(1); SELECTED+=(1); EXTERNAL+=(0); else DETECTED+=(0); SELECTED+=(0); EXTERNAL+=(0); fi

# 14: SSH Keys (iCloud)
LABELS+=("SSH Keys (iCloud)")
DESCRIPTIONS+=("~/.ssh symlink only")
if [ -L "$HOME/.ssh" ]; then DETECTED+=(1); SELECTED+=(1); EXTERNAL+=(0); else DETECTED+=(0); SELECTED+=(0); EXTERNAL+=(0); fi

# 15: Deep Clean
LABELS+=("Deep Clean")
DESCRIPTIONS+=(".cache, .local, .npm, .wakatime, .gitconfig")
DETECTED+=(1); SELECTED+=(0); EXTERNAL+=(0)

_total=${#LABELS[@]}

# ========== Draw Menu ==========
draw_menu() {
  echo ""
  echo -e "${BOLD}${MAGENTA}╔══════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${MAGENTA}║          dotfiles uninstaller — macOS            ║${NC}"
  echo -e "${BOLD}${MAGENTA}╚══════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  ${PEACH}⚠${NC}  ${DIM}Recommended: Close all terminal sessions and apps before proceeding${NC}"
  echo ""
  local _none_managed=1 _all_checked=1
  for (( i=0; i<_total; i++ )); do
    if [ "${DETECTED[$i]}" = "1" ] && [ "${EXTERNAL[$i]}" = "0" ]; then
      _none_managed=0
      [ "${SELECTED[$i]}" = "0" ] && _all_checked=0
    fi
  done
  if [ "$_none_managed" = "1" ]; then
    echo -e "  ${BOLD}${GREEN}Nothing to uninstall — system is already clean!${NC}"
    echo ""
  elif [ "$_all_checked" = "1" ]; then
    echo -e "  ${BOLD}${PEACH}All detected components selected for removal!${NC}"
    echo ""
  fi
  echo -e "  ${BOLD}${CYAN}Select components to remove:${NC}"
  echo ""
  for (( i=0; i<_total; i++ )); do
    local _num; _num=$(printf "%d" $((i + 1)))
    local _label; _label=$(printf "%-22s" "${LABELS[$i]}")
    if [ "${DETECTED[$i]}" = "0" ]; then
      echo -e "    ${DIM}${_num}. [ ] ${_label} —  not found${NC}"
    elif [ "${EXTERNAL[$i]}" = "1" ]; then
      echo -e "    ${ORANGE}${_num}. [!] ${_label}${NC} ${DIM}not installed by this script — remove manually${NC}"
    elif [ "${SELECTED[$i]}" = "1" ]; then
      echo -e "    ${MAGENTA}${_num}. [x] ${_label}${NC} ${DIM}${DESCRIPTIONS[$i]}${NC}"
    else
      echo -e "    ${GRAY}${_num}. [ ] ${_label}${NC} ${DIM}${DESCRIPTIONS[$i]}${NC}"
    fi
  done
  echo ""
  echo -e "  ${GRAY}Always removed:${NC}"
  echo -e "    ${DIM}• Dotfiles symlinks (.zshrc, .hyper.js, .config/*)${NC}"
  echo -e "    ${DIM}• Cache files (.zcompdump, .node_repl_history)${NC}"
  echo ""
  echo -e "  ${GRAY}Enter number to toggle  |  ${NC}${BOLD}${CYAN}a${NC}${GRAY} = all  |  ${NC}${BOLD}${CYAN}n${NC}${GRAY} = none  |  ${NC}${BOLD}${CYAN}Enter${NC}${GRAY} = continue  |  ${NC}${BOLD}${CYAN}q${NC}${GRAY} = quit${NC}"
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
    if [ "${EXTERNAL[$_idx]}" = "1" ]; then
      echo -e "  ${ORANGE}⚠  Not installed by this script — remove manually.${NC}"
      sleep 1.5
    elif [ "${DETECTED[$_idx]}" = "1" ]; then
      [ "${SELECTED[$_idx]}" = "1" ] && SELECTED[$_idx]=0 || SELECTED[$_idx]=1
    fi
  elif [[ "$_input" = [aA] ]]; then
    for (( i=0; i<_total; i++ )); do
      [ "${DETECTED[$i]}" = "1" ] && [ "${EXTERNAL[$i]}" != "1" ] && SELECTED[$i]=1
    done
  elif [[ "$_input" = [nN] ]]; then
    for (( i=0; i<_total; i++ )); do
      SELECTED[$i]=0
    done
  elif [ -z "$_input" ]; then
    break
  elif [[ "$_input" = [qQ] ]]; then
    echo -e "\n  ${YELLOW}⏭️  Uninstallation cancelled.${NC}"
    exit 0
  fi
  # Dependency: Rust (7) selected → auto-select Solana AVM (10) and sui-move-analyzer (12) if detected
  [ "${SELECTED[7]}" = "1" ] && [ "${DETECTED[10]}" = "1" ] && [ "${EXTERNAL[10]}" != "1" ] && SELECTED[10]=1
  [ "${SELECTED[7]}" = "1" ] && [ "${DETECTED[12]}" = "1" ] && [ "${EXTERNAL[12]}" != "1" ] && SELECTED[12]=1
  # Deselect Rust (7) → auto-deselect Solana AVM (10) and sui-move-analyzer (12)
  [ "${SELECTED[7]}" = "0" ] && SELECTED[10]=0
  [ "${SELECTED[7]}" = "0" ] && SELECTED[12]=0
done

# ========== Confirmation Summary ==========
echo ""
echo -e "  ${BOLD}${RED}Will be removed:${NC}"
for (( i=0; i<_total; i++ )); do
  if [ "${SELECTED[$i]}" = "1" ]; then
    echo -e "    ${MAGENTA}✗${NC} ${LABELS[$i]}  ${DIM}${DESCRIPTIONS[$i]}${NC}"
  fi
done
echo -e "    ${MAGENTA}✗${NC} Dotfiles symlinks"
echo -e "    ${MAGENTA}✗${NC} Cache files"
echo ""

printf "  ${BOLD}${CYAN}Proceed with uninstallation?${NC} ${GRAY}[y/n]:${NC} "
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

# ========== Homebrew Formulae + Nerd Font (index 0) ==========
if [ "${SELECTED[0]}" = "1" ]; then
  step "Removing Homebrew formulae + Nerd Font"
  for _pkg in "${BREW_FORMULAE[@]}"; do
    if brew list "$_pkg" &>/dev/null; then
      brew uninstall --ignore-dependencies "$_pkg" && done_msg "Removed $_pkg" || warn_msg "Failed to remove $_pkg"
    fi
  done
  if brew list --cask font-jetbrains-mono-nerd-font &>/dev/null; then
    brew uninstall --cask font-jetbrains-mono-nerd-font && done_msg "Removed JetBrainsMono Nerd Font" || warn_msg "Failed to remove font"
  fi
  done_msg "Homebrew formulae + font done"
fi

# ========== Yabai + Skhd (index 1) ==========
if [ "${SELECTED[1]}" = "1" ]; then
  step "Removing Yabai + Skhd"
  for _pkg in yabai skhd; do
    if brew list "$_pkg" &>/dev/null; then
      brew uninstall --ignore-dependencies "$_pkg" && done_msg "Removed $_pkg" || warn_msg "Failed to remove $_pkg"
    fi
  done
fi

# ========== Ghostty (index 2) ==========
if [ "${SELECTED[2]}" = "1" ]; then
  step "Removing Ghostty"
  if brew list --cask ghostty &>/dev/null; then
    brew uninstall --cask ghostty && done_msg "Removed ghostty" || warn_msg "Failed to remove ghostty"
  elif [ -d "/Applications/Ghostty.app" ]; then
    warn_msg "Ghostty not installed via Homebrew — remove manually: drag to Trash or rm -rf /Applications/Ghostty.app"
  fi
fi

# ========== Cloudflare WARP + Hot (index 3) ==========
if [ "${SELECTED[3]}" = "1" ]; then
  step "Removing Cloudflare WARP + Hot"
  if brew list --cask cloudflare-warp &>/dev/null; then
    brew uninstall --cask cloudflare-warp && done_msg "Cloudflare WARP removed" || warn_msg "Failed to remove cloudflare-warp"
  elif [ -d "/Applications/Cloudflare WARP.app" ]; then
    warn_msg "Cloudflare WARP not installed via Homebrew — remove manually: drag to Trash"
  fi
  if brew list --cask hot &>/dev/null; then
    brew uninstall --cask hot && done_msg "Hot removed" || warn_msg "Failed to remove hot"
  elif [ -d "/Applications/Hot.app" ]; then
    warn_msg "Hot not installed via Homebrew — remove manually: drag to Trash"
  fi
fi

# ========== Google Chrome (index 4) ==========
if [ "${SELECTED[4]}" = "1" ]; then
  step "Removing Google Chrome"
  if brew list --cask google-chrome &>/dev/null; then
    brew uninstall --cask google-chrome && done_msg "Google Chrome removed" || warn_msg "Failed to remove Google Chrome"
  elif [ -d "/Applications/Google Chrome.app" ]; then
    warn_msg "Google Chrome not installed via Homebrew — remove manually: drag to Trash"
  fi
fi

# ========== OrbStack (index 5) ==========
if [ "${SELECTED[5]}" = "1" ]; then
  step "Removing OrbStack"
  if brew list --cask orbstack &>/dev/null; then
    brew uninstall --cask orbstack && done_msg "OrbStack removed" || warn_msg "Failed to remove OrbStack"
  elif [ -d "/Applications/OrbStack.app" ]; then
    warn_msg "OrbStack not installed via Homebrew — remove manually: drag to Trash"
  fi
fi

# ========== Oh My Zsh (index 6) ==========
if [ "${SELECTED[6]}" = "1" ]; then
  step "Removing Oh My Zsh"
  rm -rf "$HOME/.oh-my-zsh"
  done_msg "Oh My Zsh removed"
fi

# ========== Rust (index 7) ==========
if [ "${SELECTED[7]}" = "1" ]; then
  step "Removing Rust"
  rm -rf "$HOME/.cargo"
  rm -rf "$HOME/.rustup"
  done_msg "Rust removed"
fi

# ========== Bun (index 8) ==========
if [ "${SELECTED[8]}" = "1" ]; then
  step "Removing Bun"
  rm -rf "$HOME/.bun"
  done_msg "Bun removed"
fi

# ========== NVM (index 9) ==========
if [ "${SELECTED[9]}" = "1" ]; then
  step "Removing NVM"
  rm -rf "$HOME/.nvm"
  done_msg "NVM removed"
fi

# ========== Solana + AVM (index 10) ==========
if [ "${SELECTED[10]}" = "1" ]; then
  step "Removing Solana + AVM"
  rm -rf "$HOME/.local/share/solana"
  rm -rf "$HOME/.config/solana"
  rm -rf "$HOME/.cache/solana"
  done_msg "Solana CLI removed"
  rm -rf "$HOME/.avm"
  rm -f "$HOME/.cargo/bin/avm" "$HOME/.cargo/bin/anchor"
  done_msg "AVM + Anchor removed"
fi

# ========== suiup + Sui (index 11) ==========
if [ "${SELECTED[11]}" = "1" ]; then
  step "Removing suiup + Sui"
  rm -f "$HOME/.local/bin/suiup"
  done_msg "suiup removed"
  for _bin in sui walrus mvr; do
    [ -f "$HOME/.local/bin/$_bin" ] && rm -f "$HOME/.local/bin/$_bin" && done_msg "$_bin removed" || true
  done
  rm -rf "$HOME/.sui"
  done_msg "~/.sui removed"
  for _xdir in "$HOME/.cache" "$HOME/.local/share" "$HOME/.local/state" "$HOME/.config"; do
    for _bin in suiup sui walrus mvr; do
      [ -e "$_xdir/$_bin" ] && rm -rf "$_xdir/$_bin" && done_msg "Removed $_xdir/$_bin" || true
    done
  done
fi

# ========== sui-move-analyzer (index 12) ==========
if [ "${SELECTED[12]}" = "1" ]; then
  step "Removing sui-move-analyzer"
  rm -f "$HOME/.cargo/bin/sui-move-analyzer"
  done_msg "sui-move-analyzer removed"
fi

# ========== AI CLI Tools (index 13) ==========
if [ "${SELECTED[13]}" = "1" ]; then
  step "Removing AI CLI Tools"
  if brew list --cask claude-code &>/dev/null; then
    brew uninstall --cask claude-code && done_msg "Claude Code removed" || warn_msg "Failed to remove Claude Code"
  fi
  rm -f "$HOME/.local/bin/claude"
  rm -rf "$HOME/.local/share/claude"
  rm -rf "$HOME/.claude"
  rm -f "$HOME/.claude.json"
  rm -f "$HOME"/.claude.json.backup.*
  done_msg "Claude Code files removed"
  if brew list gemini-cli &>/dev/null; then
    brew uninstall gemini-cli && done_msg "Gemini CLI removed" || warn_msg "Failed to remove Gemini CLI"
  fi
  rm -rf "$HOME/.gemini"
  done_msg "Gemini CLI files removed"
  if brew list kimi-cli &>/dev/null; then
    brew uninstall kimi-cli && done_msg "Kimi CLI removed" || warn_msg "Failed to remove Kimi CLI"
  fi
  rm -rf "$HOME/.kimi"
  done_msg "Kimi CLI files removed"
  if brew list opencode-ai/tap/opencode &>/dev/null; then
    brew uninstall opencode-ai/tap/opencode && done_msg "OpenCode removed" || warn_msg "Failed to remove OpenCode"
  fi
  rm -rf "$HOME/.opencode"
  done_msg "OpenCode files removed"
fi

# ========== SSH Keys (index 14) ==========
if [ "${SELECTED[14]}" = "1" ]; then
  step "Removing SSH Keys symlink"
  if [ -L "$HOME/.ssh" ]; then
    rm -f "$HOME/.ssh"
    done_msg "~/.ssh symlink removed (keys in iCloud are untouched)"
  else
    done_msg "~/.ssh is not a symlink, skipping"
  fi
fi

# ========== Cache Files (always) ==========
step "Cleaning up cache files"
rm -f "$HOME"/.zcompdump*
rm -f "$HOME/.node_repl_history"
rm -rf "$HOME/.config/github-copilot" 2>/dev/null || true
done_msg "Cache files removed"

# ========== Deep Clean (index 15) ==========
if [ "${SELECTED[15]}" = "1" ]; then
  step "Deep cleaning residue files"

  # Kill running processes that might recreate files
  for _proc in yazi neofetch; do
    pkill -9 "$_proc" 2>/dev/null || true
  done

  # XDG directories - first pass
  for _dir in "$HOME/.cache" "$HOME/.local/share" "$HOME/.local/state" "$HOME/.config"; do
    for _tool in "${TOOL_NAMES[@]}"; do
      if [ -e "$_dir/$_tool" ]; then
        rm -rf "$_dir/$_tool"
        done_msg "Removed $_dir/$_tool"
      fi
    done
  done

  # Second pass: ensure .local subdirectories are fully cleaned
  sleep 0.5  # Brief pause to catch any recreation attempts
  for _dir in "$HOME/.cache" "$HOME/.local/share" "$HOME/.local/state" "$HOME/.config"; do
    for _tool in "${TOOL_NAMES[@]}"; do
      if [ -e "$_dir/$_tool" ]; then
        rm -rf "$_dir/$_tool"
        warn_msg "Re-removed $_dir/$_tool (was recreated by running process)"
      fi
    done
  done

  # Tool config in .config (not covered by TOOL_NAMES)
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
  rm -rf "$HOME/OrbStack" 2>/dev/null || warn_msg "~/OrbStack: permission denied — remove manually"
  rm -rf "$HOME/.claude"
  rm -f "$HOME/.claude.json"
  rm -f "$HOME/.viminfo"

  done_msg "Residue files removed"
fi

# ========== Done ==========
echo ""
echo -e "${BOLD}${MAGENTA}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${MAGENTA}║           ✓ Uninstallation complete!             ║${NC}"
echo -e "${BOLD}${MAGENTA}╚══════════════════════════════════════════════════╝${NC}"
echo ""
[ "$_did_backup" = "1" ] && echo -e "  ${GREEN}📦${NC} Backup: ${CYAN}$UNINSTALL_BACKUP_DIR${NC}"
echo -e "  ${CYAN}👉 Restart your terminal or run: exec zsh${NC}"
echo ""
