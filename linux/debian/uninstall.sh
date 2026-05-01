#!/bin/bash
set -e

# ========== Tool Names for Deep Clean ==========
TOOL_NAMES=(nvim starship yazi tmux neofetch gh ripgrep htop fzf)

# ========== Colors (Miku Cyberpunk Theme — VPS variant) ==========
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
if [[ "$(uname)" != "Linux" ]]; then
  echo -e "${RED}❌ This script is for Linux only.${NC}"
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

# ========== Detect Installed Components ==========
LABELS=()
DESCRIPTIONS=()
SELECTED=()
DETECTED=()
EXTERNAL=()   # 1 = found but not at script's expected path — cannot auto-remove

# 0: Custom User
LABELS+=("Custom User")
_custom_users=()
while IFS=: read -r _u _ _uid _; do
  if [ "$_uid" -ge 1000 ] && [ "$_uid" -lt 65534 ]; then
    case "$_u" in
      debian|azureuser|ec2-user|admin|centos|fedora|debian|cloud) ;;
      *) _custom_users+=("$_u") ;;
    esac
  fi
done < /etc/passwd
if [ "${#_custom_users[@]}" -gt 0 ]; then
  DESCRIPTIONS+=("${_custom_users[*]}")
  DETECTED+=(1); SELECTED+=(0); EXTERNAL+=(0)
else
  DESCRIPTIONS+=("no custom users found")
  DETECTED+=(0); SELECTED+=(0); EXTERNAL+=(0)
fi

# 1: APT Packages + Nerd Font
# Expected paths: nvim → /opt/nvim-linux-x86_64, yazi → /usr/local/bin/yazi, others via dpkg
_apt_count=0; _apt_external=0
# nvim
if [ -d /opt/nvim-linux-x86_64 ]; then
  ((_apt_count++)) || true
elif command -v nvim &>/dev/null; then
  ((_apt_count++)) || true; _apt_external=1
fi
# APT-managed packages
for _pkg in tmux zsh htop ripgrep neofetch gh; do
  _cmd="$_pkg"; [ "$_pkg" = "ripgrep" ] && _cmd="rg"
  if dpkg -s "$_pkg" &>/dev/null 2>&1; then
    ((_apt_count++)) || true
  elif command -v "$_cmd" &>/dev/null 2>&1; then
    ((_apt_count++)) || true; _apt_external=1
  fi
done
# yazi
if [ -f /usr/local/bin/yazi ]; then
  ((_apt_count++)) || true
elif command -v yazi &>/dev/null; then
  ((_apt_count++)) || true; _apt_external=1
fi
# Nerd Font
if ls "$HOME/.local/share/fonts/JetBrainsMono"*"NerdFont"* &>/dev/null 2>&1; then
  ((_apt_count++)) || true
fi
LABELS+=("APT Packages + Nerd Font")
DESCRIPTIONS+=("${_apt_count}/9 found")
if [ "$_apt_count" -gt 0 ]; then
  DETECTED+=(1)
  if [ "$_apt_external" = "1" ]; then
    SELECTED+=(0); EXTERNAL+=(1)
  else
    SELECTED+=(1); EXTERNAL+=(0)
  fi
else
  DETECTED+=(0); SELECTED+=(0); EXTERNAL+=(0)
fi

# 2: Starship — expected at /usr/local/bin/starship
LABELS+=("Starship")
DESCRIPTIONS+=("Cross-shell prompt")
if [ -f /usr/local/bin/starship ]; then
  DETECTED+=(1); SELECTED+=(1); EXTERNAL+=(0)
elif command -v starship &>/dev/null; then
  DETECTED+=(1); SELECTED+=(0); EXTERNAL+=(1)
else
  DETECTED+=(0); SELECTED+=(0); EXTERNAL+=(0)
fi

# 3: Oh My Zsh
LABELS+=("Oh My Zsh")
DESCRIPTIONS+=("~/.oh-my-zsh")
if [ -d "$HOME/.oh-my-zsh" ]; then DETECTED+=(1); SELECTED+=(1); EXTERNAL+=(0); else DETECTED+=(0); SELECTED+=(0); EXTERNAL+=(0); fi

# 4: Rust
LABELS+=("Rust")
DESCRIPTIONS+=("~/.cargo, ~/.rustup")
if [ -d "$HOME/.cargo" ] || [ -d "$HOME/.rustup" ]; then DETECTED+=(1); SELECTED+=(1); EXTERNAL+=(0); else DETECTED+=(0); SELECTED+=(0); EXTERNAL+=(0); fi

# 5: Bun
LABELS+=("Bun")
DESCRIPTIONS+=("~/.bun")
if [ -d "$HOME/.bun" ]; then DETECTED+=(1); SELECTED+=(1); EXTERNAL+=(0); else DETECTED+=(0); SELECTED+=(0); EXTERNAL+=(0); fi

# 6: mise
LABELS+=("mise")
DESCRIPTIONS+=("~/.local/share/mise, ~/.local/bin/mise")
if command -v mise &>/dev/null || [ -d "$HOME/.local/share/mise" ]; then DETECTED+=(1); SELECTED+=(1); EXTERNAL+=(0); else DETECTED+=(0); SELECTED+=(0); EXTERNAL+=(0); fi

# 7: Docker — expected via apt docker-ce repo
LABELS+=("Docker")
DESCRIPTIONS+=("Docker engine")
if dpkg -s docker-ce &>/dev/null 2>&1; then
  DETECTED+=(1); SELECTED+=(1); EXTERNAL+=(0)
elif command -v docker &>/dev/null; then
  DETECTED+=(1); SELECTED+=(0); EXTERNAL+=(1)
else
  DETECTED+=(0); SELECTED+=(0); EXTERNAL+=(0)
fi

# 8: Swap
LABELS+=("Swap")
DESCRIPTIONS+=("/swapfile")
if [ -f /swapfile ]; then DETECTED+=(1); SELECTED+=(1); EXTERNAL+=(0); else DETECTED+=(0); SELECTED+=(0); EXTERNAL+=(0); fi

# 10: fail2ban
LABELS+=("fail2ban")
DESCRIPTIONS+=("Intrusion prevention")
if dpkg -s fail2ban &>/dev/null 2>&1; then
  DETECTED+=(1); SELECTED+=(1); EXTERNAL+=(0)
elif command -v fail2ban-client &>/dev/null; then
  DETECTED+=(1); SELECTED+=(0); EXTERNAL+=(1)
else
  DETECTED+=(0); SELECTED+=(0); EXTERNAL+=(0)
fi

# 11: UFW
LABELS+=("UFW")
DESCRIPTIONS+=("Firewall")
if command -v ufw &>/dev/null && sudo -n ufw status 2>/dev/null | grep -q "active"; then DETECTED+=(1); SELECTED+=(1); EXTERNAL+=(0); else DETECTED+=(0); SELECTED+=(0); EXTERNAL+=(0); fi

# 12: Deep Clean
LABELS+=("Deep Clean")
DESCRIPTIONS+=(".cache, .local, .npm, .gitconfig")
DETECTED+=(1); SELECTED+=(0); EXTERNAL+=(0)

_total=${#LABELS[@]}

# ========== Draw Menu ==========
draw_menu() {
  echo ""
  echo -e "${BOLD}${MAGENTA}╔══════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${MAGENTA}║           dotfiles uninstaller — VPS             ║${NC}"
  echo -e "${BOLD}${MAGENTA}╚══════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  ${PEACH}⚠${NC}  ${DIM}Recommended: Close all terminal sessions before proceeding${NC}"
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
    local _num; _num=$(printf "%2d" $((i + 1)))
    local _label; _label=$(printf "%-22s" "${LABELS[$i]}")
    if [ "${DETECTED[$i]}" = "0" ]; then
      echo -e "    ${DIM}${_num}. [ ] ${_label} —  not found${NC}"
    elif [ "${EXTERNAL[$i]}" = "1" ]; then
      echo -e "    ${ORANGE}${_num}. [!] ${_label}${NC} ${DIM}not installed by this script — remove manually${NC}"
    elif [ "${SELECTED[$i]}" = "1" ]; then
      echo -e "    ${CYAN}${_num}. [x] ${_label}${NC} ${DIM}${DESCRIPTIONS[$i]}${NC}"
    else
      echo -e "    ${GRAY}${_num}. [ ] ${_label}${NC} ${DIM}${DESCRIPTIONS[$i]}${NC}"
    fi
  done
  echo ""
  echo -e "  ${GRAY}Always removed:${NC}"
  echo -e "    ${DIM}• Dotfiles symlinks (.zshrc, shared/.config/*)${NC}"
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
done

# ========== Confirmation Summary ==========
echo ""
echo -e "  ${BOLD}${MAGENTA}Will be removed:${NC}"
for (( i=0; i<_total; i++ )); do
  if [ "${SELECTED[$i]}" = "1" ]; then
    echo -e "    ${RED}✗${NC} ${LABELS[$i]}  ${DIM}${DESCRIPTIONS[$i]}${NC}"
  fi
done
echo -e "    ${RED}✗${NC} Dotfiles symlinks"
echo -e "    ${RED}✗${NC} Cache files"
echo ""

printf "  ${BOLD}${MAGENTA}Proceed with uninstallation?${NC} [y/n]: "
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
SHARED_DIR="$DOTFILES_DIR/shared"
PLATFORM_DIR="$DOTFILES_DIR/debian"
UNINSTALL_BACKUP_DIR="$HOME/.config/backup-uninstall-$(date +%Y%m%d-%H%M%S)"
_did_backup=0

step "Creating backup of current configs"
for _d in "$SHARED_DIR/.config"/*/; do
  [ -d "$_d" ] || continue
  _name="$(basename "$_d")"
  _home_d="$HOME/.config/$_name"
  if [ -e "$_home_d" ]; then
    [ "$_did_backup" = "0" ] && mkdir -p "$UNINSTALL_BACKUP_DIR/.config"
    cp -rL "$_home_d" "$UNINSTALL_BACKUP_DIR/.config/" 2>/dev/null || true
    _did_backup=1
  fi
done
for _f in "$HOME/.zshrc"; do
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
for _d in "$HOME/.config"/*; do
  [ -L "$_d" ] && rm -f "$_d"
done
done_msg "Symlinks removed"

# ========== Custom User (index 0) ==========
if [ "${SELECTED[0]}" = "1" ]; then
  step "Removing Custom User(s)"
  for _u in "${_custom_users[@]}"; do
    if confirm "Delete user '$_u' and its home directory?"; then
      sudo userdel -r "$_u" 2>/dev/null && done_msg "User $_u removed" || warn_msg "Failed to remove $_u"
      # Remove SSH Match block for this user
      _sshd="/etc/ssh/sshd_config"
      if [ -f "$_sshd" ] && sudo grep -q "^Match User $_u$" "$_sshd" 2>/dev/null; then
        sudo awk "/^Match User $_u\$/ { skip=1; next } skip && /^[[:space:]]/ { next } { skip=0; print }" "$_sshd" | sudo tee "$_sshd.tmp" > /dev/null && sudo mv "$_sshd.tmp" "$_sshd" || true
        sudo sshd -t 2>/dev/null && (sudo systemctl restart sshd 2>/dev/null || sudo service ssh restart 2>/dev/null || true) || true
        done_msg "SSH config cleaned for $_u"
      fi
    fi
  done
fi

# ========== APT Packages + Nerd Font (index 1) ==========
if [ "${SELECTED[1]}" = "1" ]; then
  step "Removing APT packages + Nerd Font"
  # Neovim (manual install)
  if [ -d /opt/nvim-linux-x86_64 ]; then
    sudo rm -rf /opt/nvim-linux-x86_64
    sudo rm -f /usr/local/bin/nvim
    done_msg "Neovim removed"
  elif dpkg -s neovim &>/dev/null; then
    sudo apt remove -y neovim && done_msg "Neovim removed" || warn_msg "Failed to remove neovim"
  fi
  # APT packages
  for _pkg in tmux zsh htop ripgrep neofetch fzf imagemagick; do
    if dpkg -s "$_pkg" &>/dev/null; then
      sudo apt remove -y "$_pkg" && done_msg "Removed $_pkg" || warn_msg "Failed to remove $_pkg"
    fi
  done
  # yazi (manual install)
  if [ -f /usr/local/bin/yazi ]; then
    sudo rm -f /usr/local/bin/yazi
    done_msg "yazi removed"
  fi
  # gh
  if dpkg -s gh &>/dev/null; then
    sudo apt remove -y gh && done_msg "gh removed" || warn_msg "Failed to remove gh"
  fi
  # Nerd Font
  if ls "$HOME/.local/share/fonts/JetBrainsMono"* &>/dev/null 2>&1; then
    rm -f "$HOME/.local/share/fonts/JetBrainsMono"*
    fc-cache -fv > /dev/null 2>&1
    done_msg "JetBrainsMono Nerd Font removed"
  fi
  done_msg "APT packages + font done"
fi

# ========== Starship (index 2) ==========
if [ "${SELECTED[2]}" = "1" ]; then
  step "Removing Starship"
  sudo rm -f /usr/local/bin/starship
  done_msg "Starship removed"
fi

# ========== Oh My Zsh (index 3) ==========
if [ "${SELECTED[3]}" = "1" ]; then
  step "Removing Oh My Zsh"
  rm -rf "$HOME/.oh-my-zsh"
  done_msg "Oh My Zsh removed"
fi

# ========== Rust (index 4) ==========
if [ "${SELECTED[4]}" = "1" ]; then
  step "Removing Rust"
  rm -rf "$HOME/.cargo"
  rm -rf "$HOME/.rustup"
  done_msg "Rust removed"
fi

# ========== Bun (index 5) ==========
if [ "${SELECTED[5]}" = "1" ]; then
  step "Removing Bun"
  rm -rf "$HOME/.bun"
  done_msg "Bun removed"
fi

# ========== mise (index 6) ==========
if [ "${SELECTED[6]}" = "1" ]; then
  step "Removing mise"
  rm -rf "$HOME/.local/share/mise"
  rm -rf "$HOME/.config/mise"
  rm -rf "$HOME/.cache/mise"
  rm -f "$HOME/.local/bin/mise"
  done_msg "mise removed"
fi

# ========== Docker (index 7) ==========
if [ "${SELECTED[7]}" = "1" ]; then
  step "Removing Docker"
  sudo apt remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
  sudo apt autoremove -y
  sudo rm -rf /var/lib/docker /var/lib/containerd
  done_msg "Docker removed"
fi

# ========== Swap (index 8) ==========
if [ "${SELECTED[8]}" = "1" ]; then
  step "Removing swap"
  if [ -f /swapfile ]; then
    sudo swapoff /swapfile 2>/dev/null || true
    sudo rm -f /swapfile
    sudo sed -i '/\/swapfile/d' /etc/fstab
    done_msg "Swap file removed"
  fi
fi

# ========== fail2ban (index 9) ==========
if [ "${SELECTED[9]}" = "1" ]; then
  step "Removing fail2ban"
  sudo systemctl stop fail2ban 2>/dev/null || true
  sudo apt remove -y fail2ban
  done_msg "fail2ban removed"
fi

# ========== UFW (index 11) ==========
if [ "${SELECTED[11]}" = "1" ]; then
  step "Removing UFW"
  echo "y" | sudo ufw disable 2>/dev/null || true
  sudo apt remove -y ufw
  done_msg "UFW removed"
fi

# ========== Cache Files (always) ==========
step "Cleaning up cache files"
rm -f "$HOME"/.zcompdump*
rm -f "$HOME/.node_repl_history"
done_msg "Cache files removed"

# ========== Deep Clean (index 11) ==========
if [ "${SELECTED[11]}" = "1" ]; then
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

  # Second pass: ensure cleanup
  sleep 0.5
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
  rm -rf "$HOME/.npm"
  rm -f "$HOME/.viminfo"

  done_msg "Residue files removed"
fi

# ========== Revert Shell to Bash ==========
step "Reverting default shell to bash"
if [ "$SHELL" != "/bin/bash" ]; then
  sudo chsh -s /bin/bash "$USER" 2>/dev/null && done_msg "Default shell set to bash" || warn_msg "chsh failed"
else
  done_msg "Default shell already bash"
fi

# Remove bashrc zsh fallback
if [ -f "$HOME/.bashrc" ]; then
  sed -i '/exec zsh/d' "$HOME/.bashrc" 2>/dev/null || true
  sed -i '/Switch to zsh/d' "$HOME/.bashrc" 2>/dev/null || true
  done_msg "Removed zsh fallback from .bashrc"
fi

# ========== Done ==========
echo ""
echo -e "${BOLD}${MAGENTA}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${MAGENTA}║           ✓ Uninstallation complete!             ║${NC}"
echo -e "${BOLD}${MAGENTA}╚══════════════════════════════════════════════════╝${NC}"
echo ""
[ "$_did_backup" = "1" ] && echo -e "  ${CYAN}📦${NC} Backup: ${CYAN}$UNINSTALL_BACKUP_DIR${NC}"
echo -e "  ${DIM}👉 Restart your terminal or run: exec bash${NC}"
echo ""
