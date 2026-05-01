#!/bin/bash
set -e

CYAN='\033[38;2;0;217;255m'
GREEN='\033[38;2;80;250;123m'
MAGENTA='\033[38;2;255;121;198m'
RED='\033[38;2;255;85;85m'
YELLOW='\033[38;2;241;250;140m'
PEACH='\033[38;2;240;202;164m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

step()     { echo -e "\n${BOLD}${MAGENTA}  ◆ $1${NC}"; }
done_msg() { echo -e "  ${GREEN}✔${NC} $1"; }
warn_msg() { echo -e "  ${PEACH}▸${NC} $1"; }

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

if [[ "$(uname)" != "Linux" ]] || [[ ! -f /etc/arch-release ]]; then
  echo -e "${RED}❌ This script is for Arch Linux only.${NC}"
  exit 1
fi

echo ""
echo -e "${BOLD}${MAGENTA}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${MAGENTA}║            dotfiles uninstaller — Arch           ║${NC}"
echo -e "${BOLD}${MAGENTA}╚══════════════════════════════════════════════════╝${NC}"
echo ""

DOTFILES_DIR="$HOME/.dotfiles"
SHARED_DIR="$DOTFILES_DIR/shared"
PLATFORM_DIR="$DOTFILES_DIR/arch"
UNINSTALL_BACKUP_DIR="$HOME/.config/backup-uninstall-$(date +%Y%m%d-%H%M%S)"
_did_backup=0

# ========== Backup Current Configs ==========
step "Creating backup of current configs"
for _d in "$SHARED_DIR/.config"/*/ "$PLATFORM_DIR/.config"/*/; do
  [ -d "$_d" ] || continue
  _name="$(basename "$_d")"
  _home_d="$HOME/.config/$_name"
  if [ -e "$_home_d" ]; then
    [ "$_did_backup" = "0" ] && mkdir -p "$UNINSTALL_BACKUP_DIR/.config"
    cp -rL "$_home_d" "$UNINSTALL_BACKUP_DIR/.config/" 2>/dev/null || true
    _did_backup=1
  fi
done
for _f in "$HOME/.zshrc" "$HOME/.zprofile"; do
  if [ -e "$_f" ]; then
    [ "$_did_backup" = "0" ] && mkdir -p "$UNINSTALL_BACKUP_DIR"
    cp -L "$_f" "$UNINSTALL_BACKUP_DIR/" 2>/dev/null || true
    _did_backup=1
  fi
done
[ "$_did_backup" = "1" ] && done_msg "Backed up to: $UNINSTALL_BACKUP_DIR" || done_msg "No configs to backup"

# ========== Remove Symlinks ==========
step "Removing dotfiles symlinks"
rm -f "$HOME/.zshrc" "$HOME/.zprofile"
done_msg "~/.zshrc removed"
done_msg "~/.zprofile removed"
for _d in "$SHARED_DIR/.config"/*/; do
  [ -d "$_d" ] || continue
  _name="$(basename "$_d")"
  _link="$HOME/.config/$_name"
  if [ -L "$_link" ]; then
    rm -f "$_link"
    done_msg "~/.config/$_name removed"
  fi
done
for _d in "$PLATFORM_DIR/.config"/*/; do
  [ -d "$_d" ] || continue
  _name="$(basename "$_d")"
  _link="$HOME/.config/$_name"
  if [ -L "$_link" ]; then
    rm -f "$_link"
    done_msg "~/.config/$_name removed"
  fi
done
for _f in "$PLATFORM_DIR/.local/bin"/*; do
  [ -f "$_f" ] || continue
  _name="$(basename "$_f")"
  _link="$HOME/.local/bin/$_name"
  if [ -L "$_link" ]; then
    rm -f "$_link"
    done_msg "~/.local/bin/$_name removed"
  fi
done
if [ -d "$SHARED_DIR/.local/bin" ]; then
  for _f in "$SHARED_DIR/.local/bin"/*; do
    [ -f "$_f" ] || continue
    _name="$(basename "$_f")"
    _link="$HOME/.local/bin/$_name"
    if [ -L "$_link" ]; then
      rm -f "$_link"
      done_msg "~/.local/bin/$_name removed"
    fi
  done
fi

# ========== Remove Claude statusline ==========
if [ -L "$HOME/.claude/statusline-command.sh" ]; then
  rm -f "$HOME/.claude/statusline-command.sh"
  done_msg "~/.claude/statusline-command.sh removed"
fi

# ========== Remove .hushlogin ==========
if [ -f "$HOME/.hushlogin" ]; then
  rm -f "$HOME/.hushlogin"
  done_msg ".hushlogin removed"
fi

# ========== Optional: Remove Tools ==========
echo ""
if confirm "Remove Oh My Zsh?"; then
  if [ -d "$HOME/.oh-my-zsh" ]; then
    rm -rf "$HOME/.oh-my-zsh"
    done_msg "Oh My Zsh removed"
  else
    done_msg "Oh My Zsh not found"
  fi
fi

if confirm "Remove Starship?"; then
  if [ -f /usr/local/bin/starship ]; then
    sudo rm -f /usr/local/bin/starship
    done_msg "Starship removed"
  else
    done_msg "Starship not found at /usr/local/bin/starship"
  fi
fi

if confirm "Remove Rust (~/.cargo, ~/.rustup)?"; then
  if [ -f "$HOME/.cargo/bin/rustup" ]; then
    "$HOME/.cargo/bin/rustup" self uninstall -y 2>/dev/null || true
    done_msg "Rust removed"
  else
    rm -rf "$HOME/.cargo" "$HOME/.rustup" 2>/dev/null || true
    done_msg "Rust directories removed"
  fi
fi

if confirm "Remove Bun (~/.bun)?"; then
  rm -rf "$HOME/.bun"
  done_msg "Bun removed"
fi

if confirm "Remove mise (~/.local/share/mise, ~/.local/bin/mise)?"; then
  rm -rf "$HOME/.local/share/mise"
  rm -f "$HOME/.local/bin/mise"
  done_msg "mise removed"
fi

if confirm "Remove Tmux plugins (~/.config/tmux/plugins)?"; then
  rm -rf "$HOME/.config/tmux/plugins"
  done_msg "Tmux plugins removed"
fi

# ========== Done ==========
echo ""
echo -e "${BOLD}${MAGENTA}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${MAGENTA}║           ✓ Uninstall complete!                  ║${NC}"
echo -e "${BOLD}${MAGENTA}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${DIM}👉 Restart your terminal to apply changes${NC}"
echo ""
