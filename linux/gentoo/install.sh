#!/bin/bash
set -e

# ========== Colors (Miku Cyberpunk Theme — Gentoo variant) ==========
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
if [[ "$(uname)" != "Linux" ]]; then
  echo -e "${RED}❌ This script is for Linux only.${NC}"
  exit 1
fi
if [[ ! -f /etc/gentoo-release ]]; then
  echo -e "${RED}❌ This script is for Gentoo Linux only.${NC}"
  exit 1
fi

# ========== TTY Check ==========
if [ ! -t 0 ] && [ ! -c /dev/tty ]; then
  echo -e "${RED}❌ This script requires an interactive terminal.${NC}"
  exit 1
fi

# ========== Resume Mode ==========
_RESUME_SEL=""
[ "$1" = "--resume" ] && [ -n "$2" ] && _RESUME_SEL="$2"

if [ -z "$_RESUME_SEL" ]; then

# ========== VPS Detection ==========
# cloud-init is present on all major cloud VPS (AWS, GCP, Azure, DO, etc.)
_is_vps=0
if [ -d /run/cloud-init ] || [ -d /var/lib/cloud/instance ]; then
  _is_vps=1
fi

echo ""

# ========== Detect Current State ==========
LABELS=()
DESCRIPTIONS=()
SELECTED=()
STATUS=()
EXTERNAL=()

# 0: Starship
LABELS+=("Starship")
DESCRIPTIONS+=("Cross-shell prompt (replaces Spaceship)")
if [ -f /usr/local/bin/starship ]; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0)
elif command -v starship &>/dev/null; then STATUS+=("installed (external)"); SELECTED+=(0); EXTERNAL+=(1)
else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

# 1: Oh My Zsh
LABELS+=("Oh My Zsh")
DESCRIPTIONS+=("Zsh framework + autosuggestions + syntax highlighting")
if [ -d "$HOME/.oh-my-zsh" ]; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0)
else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

# 2: Rust
LABELS+=("Rust")
DESCRIPTIONS+=("Rust toolchain via rustup")
if [ -f "$HOME/.cargo/bin/rustup" ]; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0)
elif command -v rustup &>/dev/null; then STATUS+=("installed (external)"); SELECTED+=(0); EXTERNAL+=(1)
else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

# 3: Bun
LABELS+=("Bun")
DESCRIPTIONS+=("JavaScript runtime")
if [ -d "$HOME/.bun" ]; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0)
else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

# 4: mise + Node 24
LABELS+=("mise + Node 24")
DESCRIPTIONS+=("Blazingly-fast polyglot version manager + Node.js 24")
if command -v mise &>/dev/null; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0)
else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

# 5: Docker
LABELS+=("Docker")
DESCRIPTIONS+=("Container engine + add user to docker group")
if command -v docker &>/dev/null; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0)
else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

# 6: AI CLI Tools
LABELS+=("AI CLI Tools")
DESCRIPTIONS+=("Kimi CLI + OpenCode")
_ai_count=0
command -v kimi &>/dev/null && ((_ai_count++)) || true
command -v opencode &>/dev/null && ((_ai_count++)) || true
if [ "$_ai_count" -eq 2 ]; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0)
elif [ "$_ai_count" -gt 0 ]; then STATUS+=("partial"); SELECTED+=(1); EXTERNAL+=(0)
else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

# 7: Neovim Plugins (Lazy)
LABELS+=("Neovim Plugins (Lazy)")
DESCRIPTIONS+=("Headless Lazy sync — install/update all plugins")
_lazy_dir="$HOME/.local/share/nvim/lazy"
_lazy_count=0
[ -d "$_lazy_dir" ] && _lazy_count=$(ls -1 "$_lazy_dir" 2>/dev/null | wc -l | tr -d ' ')
if ! command -v nvim &>/dev/null; then STATUS+=("nvim not installed"); SELECTED+=(0); EXTERNAL+=(1)
elif [ "$_lazy_count" -gt 0 ]; then STATUS+=("${_lazy_count} plugins installed"); SELECTED+=(0); EXTERNAL+=(0)
else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

# 8: Neovim LSPs (Mason)
LABELS+=("Neovim LSPs (Mason)")
DESCRIPTIONS+=("Install LSPs + formatters via Mason")
_mason_dir="$HOME/.local/share/nvim/mason/packages"
_mason_count=0
[ -d "$_mason_dir" ] && _mason_count=$(ls -1 "$_mason_dir" 2>/dev/null | wc -l | tr -d ' ')
if ! command -v nvim &>/dev/null; then STATUS+=("nvim not installed"); SELECTED+=(0); EXTERNAL+=(1)
elif [ "$_mason_count" -gt 0 ]; then STATUS+=("${_mason_count} packages installed"); SELECTED+=(0); EXTERNAL+=(0)
else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

_total=${#LABELS[@]}

# ========== Draw Menu ==========
draw_menu() {
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${CYAN}║          dotfiles installer — Gentoo             ║${NC}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════╝${NC}"
  echo ""
  if [ "$_is_vps" = "1" ]; then
    echo -e "  ${TEAL}${BOLD}ℹ  VPS environment detected${NC}"
    echo ""
  fi
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
    local _label_color="${_label}"
    if [ "${EXTERNAL[$i]}" = "1" ]; then
      echo -e "    ${ORANGE}${_num}. [!] ${_label_color}${NC} ${DIM}not installed by this script — manage manually${NC}${_status}"
    elif [ "${SELECTED[$i]}" = "1" ]; then
      echo -e "    ${CYAN}${_num}. [x] ${_label_color}${NC} ${DIM}${DESCRIPTIONS[$i]}${NC}${_status}"
    else
      echo -e "    ${GRAY}${_num}. [ ] ${_label_color}${NC} ${DIM}${DESCRIPTIONS[$i]}${NC}${_status}"
    fi
  done
  echo ""
  echo -e "  ${GRAY}Always included:${NC}"
  echo -e "    ${DIM}• Dotfiles repo, Backup, Symlinks${NC}"
  echo -e "    ${DIM}• Shell cleanup, Git config${NC}"
  echo -e "    ${DIM}• Zsh as default shell + bashrc fallback${NC}"
  echo -e "    ${DIM}• Tmux plugins${NC}"
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
done

# ========== Confirmation ==========
echo ""
echo -e "  ${BOLD}${CYAN}Will be installed:${NC}"
for (( i=0; i<_total; i++ )); do
  if [ "${SELECTED[$i]}" = "1" ]; then
    echo -e "    ${GREEN}+${NC} ${LABELS[$i]}  ${DIM}${DESCRIPTIONS[$i]}${NC}"
  fi
done
echo -e "    ${GREEN}+${NC} Dotfiles, Symlinks  ${DIM}(always)${NC}"
echo ""

printf "  ${BOLD}${CYAN}Proceed with installation?${NC} [y/n]: "
read -r _confirm < /dev/tty
case "$_confirm" in
  [yY]|[yY][eE][sS]) ;;
  *)
    echo -e "\n  ${YELLOW}⏭️  Installation cancelled.${NC}"
    exit 0
    ;;
esac

echo ""

# ========== Essential Tools Check ==========
step "Checking essential tools"
_missing_tools=()
for _tool in git curl wget unzip zsh tmux nvim trash-put luarocks; do
  if command -v "$_tool" &>/dev/null; then
    done_msg "$_tool found"
  else
    warn_msg "$_tool not found — install via portage before continuing"
    _missing_tools+=("$_tool")
  fi
done
if [ "${#_missing_tools[@]}" -gt 0 ]; then
  echo ""
  warn_msg "Missing tools: ${_missing_tools[*]}"
  warn_msg "Install them via: sudo emerge dev-vcs/git net-misc/curl net-misc/wget app-arch/unzip app-shells/zsh app-misc/tmux app-editors/neovim app-misc/trash-cli dev-lua/luarocks"
  if ! confirm "Continue anyway?"; then
    echo -e "\n  ${YELLOW}⏭️  Aborted. Install missing tools first.${NC}"
    exit 1
  fi
fi

step "Checking Hyprland / desktop tools"
_hypr_missing=()
for _tool in hyprctl waybar wofi ghostty hyprlock hyprpaper grim slurp dunstify brightnessctl wl-copy wl-paste wtype cliphist python3 libinput ydotoold; do
  if command -v "$_tool" &>/dev/null; then
    done_msg "$_tool found"
  else
    warn_msg "$_tool not found"
    _hypr_missing+=("$_tool")
  fi
done
if command -v python3 &>/dev/null; then
  if python3 - <<'PY' >/dev/null 2>&1
import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("GdkPixbuf", "2.0")
from gi.repository import Gtk, Gdk, GdkPixbuf
PY
  then
    done_msg "Python GTK bindings found"
  else
    warn_msg "Python GTK bindings not found"
    _hypr_missing+=("python-gtk")
  fi
fi
if [ "${#_hypr_missing[@]}" -gt 0 ]; then
  echo ""
  warn_msg "Missing desktop tools: ${_hypr_missing[*]}"
  warn_msg "Install via portage, e.g.: sudo emerge gui-wm/hyprland gui-apps/waybar gui-apps/wofi gui-apps/grim gui-apps/slurp gui-apps/wl-clipboard x11-misc/dunst x11-misc/ydotool dev-libs/libinput x11-libs/gtk+ x11-libs/gdk-pixbuf dev-python/pygobject"
  warn_msg "wtype + cliphist require unmask: echo 'gui-apps/wtype ~amd64' | sudo tee /etc/portage/package.accept_keywords/wtype && echo 'app-misc/cliphist ~amd64' | sudo tee /etc/portage/package.accept_keywords/cliphist && sudo emerge gui-apps/wtype app-misc/cliphist"
  warn_msg "Optional: install gui-apps/swww for smoother wallpaper transitions. hyprpaper fallback still works."
  warn_msg "Three-finger drag also needs libinput device access and an accessible ydotoold socket."
  warn_msg "Gesture daemon logs to ~/.local/state/three-finger-drag.log."
  warn_msg "Configs will still be symlinked — tools can be installed later."
fi

# ========== Dotfiles Paths ==========
DOTFILES_DIR="$HOME/.dotfiles"
SHARED_DIR="$DOTFILES_DIR/shared"
PLATFORM_DIR="$DOTFILES_DIR/linux/gentoo"
LINUX_SHARED_DIR="$DOTFILES_DIR/linux/shared"

# ========== Backup ==========
step "Checking for existing configs"
BACKUP_DIR="$HOME/.config/backup-$(date +%Y%m%d-%H%M%S)"
_did_backup=0
for _d in "$SHARED_DIR/.config"/*/ "$LINUX_SHARED_DIR/.config"/*/ "$PLATFORM_DIR/.config"/*/; do
  [ -d "$_d" ] || continue
  _name="$(basename "$_d")"
  _p="$HOME/.config/$_name"
  if [ -d "$_p" ] && [ ! -L "$_p" ]; then
    [ "$_did_backup" = "0" ] && mkdir -p "$BACKUP_DIR"
    mv "$_p" "$BACKUP_DIR/"
    _did_backup=1
  fi
done
for _f in "$HOME/.zshrc"; do
  if [ -f "$_f" ] && [ ! -L "$_f" ]; then
    [ "$_did_backup" = "0" ] && mkdir -p "$BACKUP_DIR"
    mv "$_f" "$BACKUP_DIR/"
    _did_backup=1
  fi
done
[ "$_did_backup" = "1" ] && done_msg "Backed up to: $BACKUP_DIR" || done_msg "No existing configs to backup"

for _d in "$SHARED_DIR/.config"/*/; do
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
for _f in linux/gentoo/.zshrc; do
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

else
  # ========== Resume Mode ==========
  IFS=',' read -ra SELECTED <<< "$_RESUME_SEL"
  DOTFILES_DIR="$HOME/.dotfiles"
  SHARED_DIR="$DOTFILES_DIR/shared"
  PLATFORM_DIR="$DOTFILES_DIR/linux/gentoo"
LINUX_SHARED_DIR="$DOTFILES_DIR/linux/shared"
  echo ""
  echo -e "  ${BOLD}${CYAN}Resuming installation as $(whoami)...${NC}"
  echo ""
fi

# ══════════════════════════════════════════════════
#  SELECTED: Optional components
# ══════════════════════════════════════════════════

# ========== 0: Starship ==========
if [ "${SELECTED[0]}" = "1" ]; then
  step "Installing Starship"
  if ! command -v starship &>/dev/null; then
    info_msg "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    done_msg "Starship installed"
  else
    done_msg "Starship already installed: $(starship --version | head -1)"
  fi
fi

# ========== 1: Oh My Zsh ==========
if [ "${SELECTED[1]}" = "1" ]; then
  step "Setting up Oh My Zsh"
  # Ensure zsh binary is actually available
  if ! command -v zsh &>/dev/null; then
    fail_msg "zsh not found — install via: sudo emerge app-shells/zsh"
    exit 1
  fi
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

# ========== 2: Rust ==========
if [ "${SELECTED[2]}" = "1" ]; then
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

# ========== 3: Bun ==========
if [ "${SELECTED[3]}" = "1" ]; then
  step "Setting up Bun"
  if [ ! -f "$HOME/.bun/bin/bun" ]; then
    info_msg "Installing Bun..."
    curl -fsSL https://bun.sh/install | bash
    git -C "$DOTFILES_DIR" restore linux/gentoo/.zshrc 2>/dev/null || true
    done_msg "Bun installed"
  else
    done_msg "Bun already installed: $("$HOME/.bun/bin/bun" --version)"
  fi
fi

# ========== 4: mise + Node 24 ==========
if [ "${SELECTED[4]}" = "1" ]; then
  step "Setting up mise + Node 24"
  if ! command -v mise &>/dev/null; then
    info_msg "Installing mise..."
    curl https://mise.run | sh
    export PATH="$HOME/.local/bin:$PATH"
    done_msg "mise installed: $(mise --version 2>/dev/null)"
  else
    done_msg "mise already installed: $(mise --version 2>/dev/null)"
  fi
  if ! mise ls node 2>/dev/null | grep -q "24"; then
    info_msg "Installing Node.js 24 via mise..."
    mise use --global node@24
    done_msg "Node.js 24 installed: $(mise exec node -- node --version 2>/dev/null)"
  else
    done_msg "Node.js 24 already installed"
  fi
fi

# ========== 5: Docker ==========
if [ "${SELECTED[5]}" = "1" ]; then
  step "Installing Docker"
  if ! command -v docker &>/dev/null; then
    info_msg "Installing Docker via get.docker.com..."
    curl -fsSL https://get.docker.com | sh
    done_msg "Docker installed"
  else
    done_msg "Docker already installed: $(docker --version)"
  fi
  if ! groups "$USER" | grep -q docker; then
    info_msg "Adding $USER to docker group..."
    sudo usermod -aG docker "$USER"
    done_msg "Added to docker group (re-login to take effect)"
  else
    done_msg "$USER already in docker group"
  fi
fi

# ========== 6: AI CLI Tools ==========
if [ "${SELECTED[6]}" = "1" ]; then
  step "Installing AI CLI Tools"
  # Kimi CLI (official install script via uv)
  if ! command -v kimi &>/dev/null; then
    info_msg "Installing Kimi CLI..."
    mkdir -p "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"
    curl -fsSL https://code.kimi.com/install.sh | bash
    done_msg "Kimi CLI installed"
  else
    done_msg "Kimi CLI already installed"
  fi
  # OpenCode
  if ! command -v opencode &>/dev/null; then
    info_msg "Installing OpenCode..."
    curl -fsSL https://opencode.ai/install | bash
    done_msg "OpenCode installed"
  else
    done_msg "OpenCode already installed"
  fi
  # Claude statusline
  mkdir -p "$HOME/.claude"
  if [ -f "$SHARED_DIR/.claude/statusline-command.sh" ]; then
    ln -sf "$SHARED_DIR/.claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
    done_msg "~/.claude/statusline-command.sh"
  fi
fi

# ══════════════════════════════════════════════════
#  ALWAYS: Finalize
# ══════════════════════════════════════════════════

# ========== Symlinks ==========
step "Setting up dotfiles symlinks"

mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share"

# Remove old symlinks (shared, linux/shared, platform)
for _d in "$SHARED_DIR/.config"/*/ "$LINUX_SHARED_DIR/.config"/*/ "$PLATFORM_DIR/.config"/*/; do
  [ -d "$_d" ] || continue
  rm -f "$HOME/.config/$(basename "$_d")"
done
rm -f "$HOME/.zshrc"

# Remove legacy rifuki- prefixed symlinks
for _old in "$HOME/.local/bin/rifuki-"*; do
  [ -L "$_old" ] && rm -f "$_old"
done

# Remove legacy pre-refactor symlinks (old gentoo/, arch/, debian/ paths before linux/ restructure)
for _link in "$HOME/.config"/* "$HOME/.local/bin"/* "$HOME/.local/share/applications"/* "$HOME/.local/share/icons/hicolor/scalable/apps"/* "$HOME/.zshrc" "$HOME/.zprofile"; do
  [ -L "$_link" ] || continue
  _target="$(readlink "$_link")"
  for _old_base in "$DOTFILES_DIR/gentoo" "$DOTFILES_DIR/arch" "$DOTFILES_DIR/debian"; do
    if [[ "$_target" == "$_old_base"* ]]; then
      rm -f "$_link"
      break
    fi
  done
done

# Symlink cross-platform shared configs (nvim, tmux, starship, yazi, neofetch)
for _d in "$SHARED_DIR/.config"/*/; do
  [ -d "$_d" ] || continue
  _name="$(basename "$_d")"
  ln -snf "$SHARED_DIR/.config/$_name" "$HOME/.config/$_name"
  done_msg "~/.config/$_name"
done

# Symlink linux/shared configs — skip on VPS (no desktop needed)
if [ "$_is_vps" = "0" ]; then
  for _d in "$LINUX_SHARED_DIR/.config"/*/; do
    [ -d "$_d" ] || continue
    _name="$(basename "$_d")"
    ln -snf "$LINUX_SHARED_DIR/.config/$_name" "$HOME/.config/$_name"
    done_msg "~/.config/$_name (linux/shared)"
  done

  # Symlink Gentoo-specific configs (hyprland.conf, waybar/config)
  for _d in "$PLATFORM_DIR/.config"/*/; do
    [ -d "$_d" ] || continue
    _name="$(basename "$_d")"
    ln -snf "$PLATFORM_DIR/.config/$_name" "$HOME/.config/$_name"
    done_msg "~/.config/$_name (gentoo)"
  done
else
  warn_msg "VPS detected — skipping desktop configs (hypr, waybar, wofi, dunst, ghostty)"
fi

# Symlink cross-platform shared bin scripts
if [ -d "$SHARED_DIR/.local/bin" ]; then
  for _f in "$SHARED_DIR/.local/bin"/*; do
    [ -f "$_f" ] || continue
    _name="$(basename "$_f")"
    ln -snf "$_f" "$HOME/.local/bin/$_name"
    chmod +x "$_f"
    done_msg "~/.local/bin/$_name"
  done
fi

# Symlink linux/shared + platform bin scripts — skip desktop tools on VPS
if [ "$_is_vps" = "0" ]; then
  if [ -d "$LINUX_SHARED_DIR/.local/bin" ]; then
    for _f in "$LINUX_SHARED_DIR/.local/bin"/*; do
      [ -f "$_f" ] || continue
      _name="$(basename "$_f")"
      ln -snf "$_f" "$HOME/.local/bin/$_name"
      chmod +x "$_f"
      done_msg "~/.local/bin/$_name (linux/shared)"
    done
  fi
  for _f in "$PLATFORM_DIR/.local/bin"/*; do
    [ -f "$_f" ] || continue
    _name="$(basename "$_f")"
    ln -snf "$_f" "$HOME/.local/bin/$_name"
    chmod +x "$_f"
    done_msg "~/.local/bin/$_name (gentoo)"
  done
else
  warn_msg "VPS detected — skipping desktop bin scripts (screenshot, float-toggle, zoom-toggle, three-finger-drag)"
fi

# Symlink application launchers/icons (from linux/shared)
if [ -d "$LINUX_SHARED_DIR/.local/share" ]; then
  while IFS= read -r _f; do
    _rel="${_f#"$LINUX_SHARED_DIR/.local/share/"}"
    _target="$HOME/.local/share/$_rel"
    if [[ "$_rel" == *.desktop.in ]]; then
      _target="${_target%.in}"
      mkdir -p "$(dirname "$_target")"
      sed "s|@HOME@|$HOME|g" "$_f" > "$_target"
      chmod 644 "$_target"
      done_msg "~/.local/share/${_rel%.in}"
      continue
    fi
    mkdir -p "$(dirname "$_target")"
    ln -snf "$_f" "$_target"
    done_msg "~/.local/share/$_rel"
  done < <(find "$LINUX_SHARED_DIR/.local/share" -type f | sort)
  if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
  fi
fi

# Root dotfiles
ln -snf "$PLATFORM_DIR/.zshrc" "$HOME/.zshrc"
done_msg "~/.zshrc"

# ========== Hush Login ==========
[ ! -f "$HOME/.hushlogin" ] && touch "$HOME/.hushlogin" && done_msg ".hushlogin created"

# ========== Shell Cleanup ==========
step "Cleaning up shell profiles"
for _f in "$HOME/.zprofile" "$HOME/.zshenv" "$HOME/.profile" "$HOME/.bash_profile" "$HOME/.bashrc"; do
  [ -f "$_f" ] || continue
  grep -qE 'cargo/env|NVM_DIR|nvm\.sh|bun\.sh|BUN_INSTALL|_bun' "$_f" 2>/dev/null || continue
  grep -vE 'cargo/env|NVM_DIR|nvm\.sh|bun\.sh|BUN_INSTALL|_bun|Added by.*installer|Added by nvm' "$_f" > "${_f}.tmp" || true
  if [ -s "${_f}.tmp" ]; then
    mv "${_f}.tmp" "$_f"
  else
    rm -f "${_f}.tmp" "$_f"
  fi
  done_msg "Cleaned: $(basename "$_f")"
done
done_msg "Shell profiles clean"

# ========== Bashrc Fallback ==========
step "Setting up bashrc fallback"
_bashrc="$HOME/.bashrc"
if [ -f "$_bashrc" ]; then
  if ! grep -q 'exec zsh' "$_bashrc"; then
    echo '' >> "$_bashrc"
    echo '# Switch to zsh if available' >> "$_bashrc"
    echo 'if [ -x "$(command -v zsh)" ]; then exec zsh; fi' >> "$_bashrc"
    done_msg "Added zsh fallback to .bashrc"
  else
    done_msg "Bashrc fallback already set"
  fi
else
  echo '# Switch to zsh if available' > "$_bashrc"
  echo 'if [ -x "$(command -v zsh)" ]; then exec zsh; fi' >> "$_bashrc"
  done_msg "Created .bashrc with zsh fallback"
fi

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
if [ "$SHELL" != "$(which zsh 2>/dev/null)" ]; then
  step "Setting zsh as default shell"
  if command -v zsh &>/dev/null; then
    sudo chsh -s "$(which zsh)" "$USER" || warn_msg "chsh failed"
    done_msg "Default shell set to zsh"
  else
    warn_msg "zsh not installed — install via: sudo emerge app-shells/zsh"
  fi
fi

# ========== Neovim: Lazy + Mason Headless Install ==========
if [ "${SELECTED[7]}" = "1" ] || [ "${SELECTED[8]}" = "1" ]; then
  if command -v nvim &>/dev/null && [ -d "$HOME/.config/nvim" ]; then
    if [ "${SELECTED[7]}" = "1" ]; then
      step "Syncing Neovim plugins (Lazy)"
      nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
      done_msg "Lazy plugins synced"
    fi

    if [ "${SELECTED[8]}" = "1" ]; then
      step "Installing Mason packages (LSPs + formatters)"
      # MasonInstall is blocking in headless mode — waits until all packages finish.
      # The lua -c registers progress listeners before MasonInstall fires events.
      nvim --headless \
        -c "lua local r=require('mason-registry');r:on('package:install:start',function(p)vim.api.nvim_out_write('  [mason] installing '..p.name..'...\n')end);r:on('package:install:success',function(p)vim.api.nvim_out_write('  [mason] done '..p.name..'\n')end);r:on('package:install:failed',function(p)vim.api.nvim_out_write('  [mason] FAILED '..p.name..'\n')end)" \
        -c "MasonInstall lua-language-server taplo typescript-language-server deno intelephense dockerfile-language-server yaml-language-server gh-actions-language-server json-lsp css-lsp html-lsp bash-language-server clangd prettierd stylua prisma-language-server nomicfoundation-solidity-language-server tailwindcss-language-server" \
        -c "qall" 2>/dev/null || true
      done_msg "Mason packages installed"
    fi
  else
    warn_msg "nvim not installed, skipping Neovim headless tasks"
  fi
fi

# ========== Done ==========
echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║           ✓ Installation complete!               ║${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${DIM}👉 Restart your terminal or run: exec zsh${NC}"
echo ""
