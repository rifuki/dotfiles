#!/bin/bash
set -e

# ========== Colors (Miku Cyberpunk Theme — Arch variant) ==========
CYAN='\033[38;2;0;217;255m'
GREEN='\033[38;2;80;250;123m'
MAGENTA='\033[38;2;255;121;198m'
PURPLE='\033[38;2;189;147;249m'
TEAL='\033[38;2;1;203;198m'
GRAY='\033[38;2;148;163;184m'
ORANGE='\033[38;2;255;184;108m'
PEACH='\033[38;2;240;202;164m'
RED='\033[38;2;255;85;85m'
YELLOW='\033[38;2;241;250;140m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

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

install_pacman_packages() {
  local _available=()
  local _missing=()
  local _pkg
  for _pkg in "$@"; do
    if pacman -Si "$_pkg" >/dev/null 2>&1; then
      _available+=("$_pkg")
    else
      _missing+=("$_pkg")
    fi
  done

  if [ "${#_available[@]}" -gt 0 ]; then
    sudo pacman -S --needed --noconfirm "${_available[@]}"
  fi
  if [ "${#_missing[@]}" -gt 0 ]; then
    warn_msg "Skipped unavailable packages: ${_missing[*]}"
  fi
}

# ========== OS Check ==========
if [[ "$(uname)" != "Linux" ]] || [[ ! -f /etc/arch-release ]]; then
  echo -e "${RED}❌ This script is for Arch Linux only.${NC}"
  exit 1
fi
if ! command -v pacman &>/dev/null; then
  echo -e "${RED}❌ pacman not found.${NC}"
  exit 1
fi

if [ ! -t 0 ] && [ ! -c /dev/tty ]; then
  echo -e "${RED}❌ This script requires an interactive terminal.${NC}"
  exit 1
fi

_RESUME_SEL=""
[ "${1:-}" = "--resume" ] && [ -n "${2:-}" ] && _RESUME_SEL="$2"

# ========== VPS Detection ==========
_is_vps=0
if [ -d /run/cloud-init ] || [ -d /var/lib/cloud/instance ]; then
  _is_vps=1
fi

if [ -z "$_RESUME_SEL" ]; then
  echo ""

  LABELS=()
  DESCRIPTIONS=()
  SELECTED=()
  STATUS=()
  EXTERNAL=()

  LABELS+=("Arch Desktop + Fonts")
  DESCRIPTIONS+=("Hyprland, Waybar, Wofi, Ghostty, PipeWire, NetworkManager, Bluetooth, fonts, screenshot tools")
  _desktop_count=0
  for _cmd in Hyprland waybar wofi ghostty hyprlock hyprpaper dunstify grim slurp wl-copy brightnessctl nvim zsh; do
    command -v "$_cmd" &>/dev/null && ((_desktop_count++)) || true
  done
  if ls "$HOME/.local/share/fonts/JetBrainsMono"*"NerdFont"* &>/dev/null 2>&1 || fc-match "JetBrainsMono Nerd Font" >/dev/null 2>&1; then
    ((_desktop_count++)) || true
  fi
  if [ "$_desktop_count" -ge 14 ]; then STATUS+=("ready"); SELECTED+=(0); EXTERNAL+=(0)
  elif [ "$_desktop_count" -gt 0 ]; then STATUS+=("${_desktop_count}/14 ready"); SELECTED+=(1); EXTERNAL+=(0)
  else STATUS+=("fresh system"); SELECTED+=(1); EXTERNAL+=(0); fi

  LABELS+=("Starship")
  DESCRIPTIONS+=("Cross-shell prompt")
  if command -v starship &>/dev/null; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0)
  else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

  LABELS+=("Oh My Zsh")
  DESCRIPTIONS+=("Zsh framework + autosuggestions + syntax highlighting")
  if [ -d "$HOME/.oh-my-zsh" ]; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0)
  else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

  LABELS+=("Rust")
  DESCRIPTIONS+=("Rust toolchain via rustup")
  if [ -f "$HOME/.cargo/bin/rustup" ]; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0)
  else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

  LABELS+=("Bun")
  DESCRIPTIONS+=("JavaScript runtime")
  if [ -d "$HOME/.bun" ]; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0)
  else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

  LABELS+=("mise + Node 24")
  DESCRIPTIONS+=("Polyglot version manager + Node.js 24")
  if command -v mise &>/dev/null; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0)
  else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

  LABELS+=("Docker")
  DESCRIPTIONS+=("Container engine + docker group")
  if command -v docker &>/dev/null; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0)
  else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

  LABELS+=("Neovim Plugins")
  DESCRIPTIONS+=("Headless Lazy sync")
  _lazy_count=0
  [ -d "$HOME/.local/share/nvim/lazy" ] && _lazy_count=$(ls -1 "$HOME/.local/share/nvim/lazy" 2>/dev/null | wc -l | tr -d ' ')
  if ! command -v nvim &>/dev/null; then STATUS+=("nvim missing"); SELECTED+=(0); EXTERNAL+=(1)
  elif [ "$_lazy_count" -gt 0 ]; then STATUS+=("${_lazy_count} plugins"); SELECTED+=(0); EXTERNAL+=(0)
  else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

  LABELS+=("Neovim LSPs")
  DESCRIPTIONS+=("Install LSPs + formatters via Mason")
  _mason_count=0
  [ -d "$HOME/.local/share/nvim/mason/packages" ] && _mason_count=$(ls -1 "$HOME/.local/share/nvim/mason/packages" 2>/dev/null | wc -l | tr -d ' ')
  if ! command -v nvim &>/dev/null; then STATUS+=("nvim missing"); SELECTED+=(0); EXTERNAL+=(1)
  elif [ "$_mason_count" -gt 0 ]; then STATUS+=("${_mason_count} packages"); SELECTED+=(0); EXTERNAL+=(0)
  else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

  _total=${#LABELS[@]}

  draw_menu() {
    echo ""
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║          dotfiles installer — Arch               ║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}${CYAN}Select components to install:${NC}"
    echo ""
    for (( i=0; i<_total; i++ )); do
      local _num; _num=$(printf "%2d" $((i + 1)))
      local _label; _label=$(printf "%-22s" "${LABELS[$i]}")
      local _status=""
      [ -n "${STATUS[$i]}" ] && _status=" ${TEAL}(${STATUS[$i]})${NC}"
      if [ "${EXTERNAL[$i]}" = "1" ]; then
        echo -e "    ${ORANGE}${_num}. [!] ${_label}${NC} ${DIM}not available yet${NC}${_status}"
      elif [ "${SELECTED[$i]}" = "1" ]; then
        echo -e "    ${CYAN}${_num}. [x] ${_label}${NC} ${DIM}${DESCRIPTIONS[$i]}${NC}${_status}"
      else
        echo -e "    ${TEAL}${_num}. [ ] ${_label}${NC} ${DIM}${DESCRIPTIONS[$i]}${NC}${_status}"
      fi
    done
    echo ""
    echo -e "  ${GRAY}Always included:${NC}"
    echo -e "    ${DIM}• Dotfiles symlinks, shared scripts, shell cleanup${NC}"
    echo -e "    ${DIM}• .zprofile auto-starts Hyprland on TTY1${NC}"
    echo ""
    echo -e "  Enter number to toggle  |  ${BOLD}${CYAN}a${NC} = all  |  ${BOLD}${CYAN}n${NC} = none  |  ${BOLD}${CYAN}Enter${NC} = continue  |  ${BOLD}${CYAN}q${NC} = quit"
    echo ""
  }

  while true; do
    draw_menu
    printf "  > "
    read -r _input < /dev/tty
    if [[ "$_input" =~ ^[0-9]+$ ]] && [ "$_input" -ge 1 ] && [ "$_input" -le "$_total" ]; then
      _idx=$((_input - 1))
      if [ "${EXTERNAL[$_idx]}" = "1" ]; then
        warn_msg "Cannot toggle item yet. Install dependencies first."
        sleep 1
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
      echo -e "\n  ${YELLOW}Installation cancelled.${NC}"
      exit 0
    fi
  done

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
    *) echo -e "\n  ${YELLOW}Installation cancelled.${NC}"; exit 0 ;;
  esac
else
  IFS=',' read -ra SELECTED <<< "$_RESUME_SEL"
fi

DOTFILES_DIR="$HOME/.dotfiles"
SHARED_DIR="$DOTFILES_DIR/shared"
PLATFORM_DIR="$DOTFILES_DIR/linux/arch"
LINUX_SHARED_DIR="$DOTFILES_DIR/linux/shared"

# ========== 0: Arch Desktop + Fonts ==========
if [ "${SELECTED[0]}" = "1" ]; then
  step "Installing Arch desktop packages"
  sudo pacman -Syu --noconfirm
  _desktop_pkgs=(
    base-devel git curl wget unzip zsh tmux neovim htop ripgrep fd fzf yazi lua luarocks trash-cli
    xdg-user-dirs xdg-utils fontconfig terminus-font ttf-jetbrains-mono-nerd ttf-firacode-nerd noto-fonts noto-fonts-cjk noto-fonts-emoji
    hyprland xdg-desktop-portal-hyprland waybar wofi ghostty hyprpaper hyprlock swww dunst grim slurp wl-clipboard swappy satty
    pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber pavucontrol playerctl brightnessctl
    networkmanager bluez bluez-utils blueman dolphin ark qt5-wayland qt6-wayland qt5ct qt6ct papirus-icon-theme adw-gtk-theme
    python-gobject gtk3 imagemagick polkit-kde-agent cliphist wtype github-cli
  )
  install_pacman_packages "${_desktop_pkgs[@]}"

  if command -v xdg-user-dirs-update >/dev/null 2>&1; then
    xdg-user-dirs-update || true
  fi
  mkdir -p "$HOME/.wallpapers" "$HOME/Pictures/Screenshots" "$HOME/Pictures/Wallpapers"

  if ! grep -q '^FONT=' /etc/vconsole.conf 2>/dev/null; then
    printf 'KEYMAP=us\nFONT=ter-v24b\n' | sudo tee /etc/vconsole.conf >/dev/null || true
    done_msg "TTY font configured: ter-v24b"
  fi

  sudo systemctl enable --now NetworkManager 2>/dev/null || true
  sudo systemctl enable --now bluetooth 2>/dev/null || true
  systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true
  done_msg "Arch desktop base ready"
fi

# ========== 1: Starship ==========
if [ "${SELECTED[1]}" = "1" ]; then
  step "Installing Starship"
  if ! command -v starship &>/dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    done_msg "Starship installed"
  else
    done_msg "Starship already installed: $(starship --version | head -1)"
  fi
fi

# ========== 2: Oh My Zsh ==========
if [ "${SELECTED[2]}" = "1" ]; then
  step "Setting up Oh My Zsh"
  if ! command -v zsh &>/dev/null; then
    install_pacman_packages zsh
  fi
  if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    RUNZSH=no KEEP_ZSHRC=yes CHSH=no bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    done_msg "Oh My Zsh installed"
  else
    done_msg "Oh My Zsh already installed"
  fi
  ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
  if [[ ! -f "$ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    rm -rf "$ZSH_CUSTOM/plugins/zsh-autosuggestions" 2>/dev/null || true
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  fi
  if [[ ! -f "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    rm -rf "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" 2>/dev/null || true
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  fi
  done_msg "Zsh plugins ready"
fi

# ========== 3: Rust ==========
if [ "${SELECTED[3]}" = "1" ]; then
  step "Setting up Rust"
  if [ ! -f "$HOME/.cargo/bin/rustup" ]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --no-modify-path
    source "$HOME/.cargo/env"
    done_msg "Rust installed"
  else
    source "$HOME/.cargo/env" 2>/dev/null || true
    done_msg "Rust already installed: $("$HOME/.cargo/bin/rustc" --version 2>/dev/null || true)"
  fi
fi

# ========== 4: Bun ==========
if [ "${SELECTED[4]}" = "1" ]; then
  step "Setting up Bun"
  if [ ! -f "$HOME/.bun/bin/bun" ]; then
    curl -fsSL https://bun.sh/install | bash
    git -C "$DOTFILES_DIR" restore arch/.zshrc 2>/dev/null || true
    done_msg "Bun installed"
  else
    done_msg "Bun already installed: $("$HOME/.bun/bin/bun" --version)"
  fi
fi

# ========== 5: mise + Node 24 ==========
if [ "${SELECTED[5]}" = "1" ]; then
  step "Setting up mise + Node 24"
  if ! command -v mise &>/dev/null; then
    curl https://mise.run | sh
    export PATH="$HOME/.local/bin:$PATH"
    done_msg "mise installed: $(mise --version 2>/dev/null)"
  else
    done_msg "mise already installed: $(mise --version 2>/dev/null)"
  fi
  if ! mise ls node 2>/dev/null | grep -q "24"; then
    mise use --global node@24
    done_msg "Node.js 24 installed"
  else
    done_msg "Node.js 24 already installed"
  fi
fi

# ========== 6: Docker ==========
if [ "${SELECTED[6]}" = "1" ]; then
  step "Installing Docker"
  install_pacman_packages docker docker-compose
  sudo systemctl enable --now docker 2>/dev/null || true
  if ! groups "$USER" | grep -q docker; then
    sudo usermod -aG docker "$USER"
    done_msg "Added $USER to docker group (re-login required)"
  else
    done_msg "$USER already in docker group"
  fi
fi

# ========== Always: Symlinks ==========
step "Setting up dotfiles symlinks"
mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share"

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
for _f in "$HOME/.zshrc" "$HOME/.zprofile"; do
  if [ -f "$_f" ] && [ ! -L "$_f" ]; then
    [ "$_did_backup" = "0" ] && mkdir -p "$BACKUP_DIR"
    mv "$_f" "$BACKUP_DIR/"
    _did_backup=1
  fi
done
[ "$_did_backup" = "1" ] && done_msg "Backed up to: $BACKUP_DIR" || done_msg "No existing configs to backup"

for _d in "$SHARED_DIR/.config"/*/ "$LINUX_SHARED_DIR/.config"/*/ "$PLATFORM_DIR/.config"/*/; do
  [ -d "$_d" ] || continue
  rm -f "$HOME/.config/$(basename "$_d")"
done
rm -f "$HOME/.zshrc" "$HOME/.zprofile"

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

# Symlink linux/shared + arch configs — skip desktop on VPS
if [ "$_is_vps" = "0" ]; then
  for _d in "$LINUX_SHARED_DIR/.config"/*/; do
    [ -d "$_d" ] || continue
    _name="$(basename "$_d")"
    ln -snf "$LINUX_SHARED_DIR/.config/$_name" "$HOME/.config/$_name"
    done_msg "~/.config/$_name (linux/shared)"
  done
  for _d in "$PLATFORM_DIR/.config"/*/; do
    [ -d "$_d" ] || continue
    _name="$(basename "$_d")"
    ln -snf "$PLATFORM_DIR/.config/$_name" "$HOME/.config/$_name"
    done_msg "~/.config/$_name (arch)"
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

# Symlink linux/shared + arch bin scripts — skip desktop on VPS
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
  if [ -d "$PLATFORM_DIR/.local/bin" ]; then
    for _f in "$PLATFORM_DIR/.local/bin"/*; do
      [ -f "$_f" ] || continue
      _name="$(basename "$_f")"
      ln -snf "$_f" "$HOME/.local/bin/$_name"
      chmod +x "$_f"
      done_msg "~/.local/bin/$_name (arch)"
    done
  fi
else
  warn_msg "VPS detected — skipping desktop bin scripts"
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
  command -v update-desktop-database &>/dev/null && update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
fi

ln -snf "$PLATFORM_DIR/.zshrc" "$HOME/.zshrc"
done_msg "~/.zshrc"
if [ -f "$PLATFORM_DIR/.zprofile" ]; then
  ln -snf "$PLATFORM_DIR/.zprofile" "$HOME/.zprofile"
  done_msg "~/.zprofile"
fi

# ========== Cursor Themes ==========
if [ "$_is_vps" = "0" ]; then
  step "Setting up cursor themes"

  # theme_miku-cursor (hyprcursor) — already linked file-by-file via linux/shared above
  if [ -f "$HOME/.local/share/icons/theme_miku-cursor/manifest.hl" ]; then
    done_msg "theme_miku-cursor (hyprcursor) linked"
  fi

  # miku-cursor-linux (xcursor) — download from GitHub if not installed
  if [ ! -d "$HOME/.local/share/icons/miku-cursor-linux" ]; then
    info_msg "Downloading miku-cursor-linux from GitHub..."
    _cursor_tmp="$(mktemp -d)"
    _cursor_url="$(curl -s https://api.github.com/repos/supermariofps/hatsune-miku-windows-linux-cursors/releases/latest \
      | python3 -c "
import sys, json
data = json.load(sys.stdin)
assets = data.get('assets', [])
for a in assets:
    n = a['name'].lower()
    if 'linux' in n and (n.endswith('.tar.gz') or n.endswith('.tar.xz') or n.endswith('.zip')):
        print(a['browser_download_url']); break
" 2>/dev/null)"
    if [ -n "$_cursor_url" ]; then
      _cursor_file="$_cursor_tmp/cursor-pkg"
      curl -L --progress-bar "$_cursor_url" -o "$_cursor_file"
      mkdir -p "$HOME/.local/share/icons"
      if file "$_cursor_file" | grep -q "Zip"; then
        unzip -q "$_cursor_file" -d "$HOME/.local/share/icons/"
      else
        tar -xf "$_cursor_file" -C "$HOME/.local/share/icons/"
      fi
      rm -rf "$_cursor_tmp"
      if [ -d "$HOME/.local/share/icons/miku-cursor-linux" ]; then
        done_msg "miku-cursor-linux installed"
      else
        warn_msg "Extraction succeeded but miku-cursor-linux dir not found — check archive structure"
      fi
    else
      warn_msg "Could not find Linux cursor asset — install manually from:"
      warn_msg "https://github.com/supermariofps/hatsune-miku-windows-linux-cursors/releases"
      rm -rf "$_cursor_tmp"
    fi
  else
    done_msg "miku-cursor-linux already installed"
  fi

  # Apply cursor via GSettings (GTK apps prefer dconf over settings.ini)
  if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface cursor-theme 'miku-cursor-linux' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true
    done_msg "GSettings cursor applied"
  fi
fi

[ ! -f "$HOME/.hushlogin" ] && touch "$HOME/.hushlogin" && done_msg ".hushlogin created"

step "Cleaning up shell profiles"
for _f in "$HOME/.zshenv" "$HOME/.profile" "$HOME/.bashrc"; do
  [ -f "$_f" ] || continue
  grep -qE 'cargo/env|NVM_DIR|nvm\.sh|bun\.sh|BUN_INSTALL|_bun' "$_f" 2>/dev/null || continue
  grep -vE 'cargo/env|NVM_DIR|nvm\.sh|bun\.sh|BUN_INSTALL|_bun|Added by.*installer|Added by nvm' "$_f" > "${_f}.tmp" || true
  if [ -s "${_f}.tmp" ]; then mv "${_f}.tmp" "$_f"; else rm -f "${_f}.tmp" "$_f"; fi
  done_msg "Cleaned: $(basename "$_f")"
done
done_msg "Shell profiles clean"

if [ ! -f "$HOME/.bash_profile" ]; then
  printf '%s\n' '# Start zsh login shell if available' 'if [ -x "$(command -v zsh)" ]; then exec zsh -l; fi' > "$HOME/.bash_profile"
  done_msg "Created .bash_profile zsh fallback"
fi

if command -v tmux &>/dev/null; then
  step "Setting up Tmux plugins"
  TPM_DIR="$HOME/.config/tmux/plugins/tpm"
  if [ ! -d "$TPM_DIR" ]; then
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    done_msg "TPM installed"
  else
    done_msg "TPM already installed"
  fi
  [ -x "$TPM_DIR/bin/install_plugins" ] && "$TPM_DIR/bin/install_plugins" || true
fi

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

if [ "$SHELL" != "$(which zsh 2>/dev/null)" ]; then
  step "Setting zsh as default shell"
  if command -v zsh &>/dev/null; then
    sudo chsh -s "$(which zsh)" "$USER" || warn_msg "chsh failed"
    done_msg "Default shell set to zsh"
  else
    warn_msg "zsh not installed, skipping"
  fi
fi

if command -v nvim &>/dev/null && [ -d "$HOME/.config/nvim" ]; then
  if [ "${SELECTED[7]}" = "1" ]; then
    step "Syncing Neovim plugins"
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
    done_msg "Lazy plugins synced"
  fi
  if [ "${SELECTED[8]}" = "1" ]; then
    step "Installing Mason packages"
    nvim --headless \
      -c "lua local r=require('mason-registry');r:on('package:install:start',function(p)vim.api.nvim_out_write('  [mason] installing '..p.name..'...\n')end);r:on('package:install:success',function(p)vim.api.nvim_out_write('  [mason] done '..p.name..'\n')end);r:on('package:install:failed',function(p)vim.api.nvim_out_write('  [mason] FAILED '..p.name..'\n')end)" \
      -c "MasonInstall lua-language-server taplo typescript-language-server deno intelephense dockerfile-language-server yaml-language-server gh-actions-language-server json-lsp css-lsp html-lsp bash-language-server clangd prettierd stylua prisma-language-server nomicfoundation-solidity-language-server tailwindcss-language-server" \
      -c "qall" 2>/dev/null || true
    done_msg "Mason packages installed"
  fi
fi

echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║           ✓ Arch install complete!               ║${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${DIM}Re-login on TTY1 to auto-start Hyprland, or run: Hyprland${NC}"
echo -e "  ${DIM}If Docker was installed, re-login for docker group membership.${NC}"
echo ""
