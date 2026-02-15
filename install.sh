#!/bin/bash
set -e

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
if ! command -v apt &>/dev/null; then
  echo -e "${RED}❌ This script requires apt (Debian/Ubuntu).${NC}"
  exit 1
fi

# ========== TTY Check ==========
if [ ! -t 0 ] && [ ! -c /dev/tty ]; then
  echo -e "${RED}❌ This script requires an interactive terminal.${NC}"
  exit 1
fi

# ========== Resume Mode (re-launched as custom user) ==========
_RESUME_SEL=""
[ "$1" = "--resume" ] && [ -n "$2" ] && _RESUME_SEL="$2"

if [ -z "$_RESUME_SEL" ]; then

# ========== Security Check: root / passwordless user ==========
_is_root=0
_user_no_password=0
if [ "$EUID" = "0" ] || [ "$USER" = "root" ]; then
  _is_root=1
fi
_cur_pw_status=$(sudo -n passwd -S "$USER" 2>/dev/null | awk '{print $2}' || true)
[ "$_cur_pw_status" = "NP" ] && _user_no_password=1 || true

echo ""

# ========== Detect Current State ==========
LABELS=()
DESCRIPTIONS=()
SELECTED=()
STATUS=()
EXTERNAL=()   # 1 = found but not installed by this script — cannot manage

# 0: Custom User
LABELS+=("Custom User")
DESCRIPTIONS+=("New user with password + sudo (secure alternative to default cloud user)")
_found_user=""
_found_user_has_pw=0
while IFS=: read -r _u _ _uid _; do
  if [ "$_uid" -ge 1000 ] && [ "$_uid" -lt 65534 ]; then
    case "$_u" in
      ubuntu|azureuser|ec2-user|admin|centos|fedora|debian|cloud) ;;
      *) _found_user="$_u"; break ;;
    esac
  fi
done < /etc/passwd
if [ -n "$_found_user" ]; then
  _fu_pw_status=$(sudo -n passwd -S "$_found_user" 2>/dev/null | awk '{print $2}' || true)
  if [ "$_fu_pw_status" = "P" ]; then
    _fu_pw_hash=$(sudo -n getent shadow "$_found_user" 2>/dev/null | cut -d: -f2 || true)
    case "$_fu_pw_hash" in
      ""|"!"*|"*"|"!!"*) _found_user_has_pw=0 ;;
      *) _found_user_has_pw=1 ;;
    esac
  fi
fi
if [ "$_is_root" = "1" ]; then
  SELECTED+=(1); STATUS+=("running as root"); EXTERNAL+=(0)
elif [ "$_user_no_password" = "1" ]; then
  SELECTED+=(1); STATUS+=("$USER has no password"); EXTERNAL+=(0)
elif [ -n "$_found_user" ] && [ "$_found_user_has_pw" = "1" ]; then
  SELECTED+=(0); STATUS+=("$_found_user (ready)"); EXTERNAL+=(0)
elif [ -n "$_found_user" ]; then
  SELECTED+=(1); STATUS+=("$_found_user (no password!)"); EXTERNAL+=(0)
else
  SELECTED+=(1); STATUS+=(""); EXTERNAL+=(0)
fi

# 1: APT Packages + Nerd Font
# Expected: nvim → /opt/nvim-linux-x86_64, yazi → /usr/local/bin/yazi, others via dpkg
LABELS+=("APT Packages + Nerd Font")
DESCRIPTIONS+=("neovim, tmux, zsh, htop, ripgrep, neofetch, yazi, gh, JetBrainsMono")
_fi=0; _fi_ext=0
# nvim
if [ -d /opt/nvim-linux-x86_64 ]; then ((_fi++)) || true
elif command -v nvim &>/dev/null; then ((_fi++)) || true; _fi_ext=1; fi
# APT-managed packages
for _pkg in tmux zsh htop ripgrep neofetch gh; do
  _cmd="$_pkg"; [ "$_pkg" = "ripgrep" ] && _cmd="rg"
  if dpkg -s "$_pkg" &>/dev/null 2>&1; then ((_fi++)) || true
  elif command -v "$_cmd" &>/dev/null 2>&1; then ((_fi++)) || true; _fi_ext=1; fi
done
# yazi
if [ -f /usr/local/bin/yazi ]; then ((_fi++)) || true
elif command -v yazi &>/dev/null; then ((_fi++)) || true; _fi_ext=1; fi
# Nerd Font
if ls "$HOME/.local/share/fonts/JetBrainsMono"*"NerdFont"* &>/dev/null 2>&1; then ((_fi++)) || true; fi
if [ "$_fi" -gt 0 ] && [ "$_fi_ext" = "1" ]; then STATUS+=("${_fi}/9 installed (external)"); SELECTED+=(0); EXTERNAL+=(1)
elif [ "$_fi" -eq 9 ]; then STATUS+=("all installed"); SELECTED+=(0); EXTERNAL+=(0)
elif [ "$_fi" -gt 0 ]; then STATUS+=("${_fi}/9 installed"); SELECTED+=(1); EXTERNAL+=(0)
else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

# 2: Starship — expected at /usr/local/bin/starship
LABELS+=("Starship")
DESCRIPTIONS+=("Cross-shell prompt theme")
if [ -f /usr/local/bin/starship ]; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0)
elif command -v starship &>/dev/null; then STATUS+=("installed (external)"); SELECTED+=(0); EXTERNAL+=(1)
else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

# 3: Oh My Zsh
LABELS+=("Oh My Zsh")
DESCRIPTIONS+=("Zsh framework + plugins")
if [ -d "$HOME/.oh-my-zsh" ]; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0); else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

# 4: Rust
LABELS+=("Rust")
DESCRIPTIONS+=("Rust toolchain via rustup")
if [ -f "$HOME/.cargo/bin/rustup" ]; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0); else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

# 5: Bun
LABELS+=("Bun")
DESCRIPTIONS+=("JavaScript runtime")
if [ -d "$HOME/.bun" ]; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0); else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

# 6: NVM + Node 24
LABELS+=("NVM + Node 24")
DESCRIPTIONS+=("Node Version Manager + Node.js")
if [ -d "$HOME/.nvm" ]; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0); else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

# 7: Docker — expected via apt docker-ce repo
LABELS+=("Docker")
DESCRIPTIONS+=("Container engine + add user to docker group")
if dpkg -s docker-ce &>/dev/null 2>&1; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0)
elif command -v docker &>/dev/null; then STATUS+=("installed (external)"); SELECTED+=(0); EXTERNAL+=(1)
else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

# 8: AI CLI Tools
LABELS+=("AI CLI Tools")
DESCRIPTIONS+=("Claude Code + Gemini CLI (requires NVM)")
if command -v claude &>/dev/null && command -v gemini &>/dev/null; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0)
elif command -v claude &>/dev/null || command -v gemini &>/dev/null; then STATUS+=("partial"); SELECTED+=(1); EXTERNAL+=(0)
else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

# 9: Swap (2GB)
LABELS+=("Swap (2GB)")
DESCRIPTIONS+=("Create 2GB swap file")
if [ -f /swapfile ]; then STATUS+=("active"); SELECTED+=(0); EXTERNAL+=(0); else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

# 10: fail2ban
LABELS+=("fail2ban")
DESCRIPTIONS+=("Intrusion prevention")
if dpkg -s fail2ban &>/dev/null 2>&1; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0)
elif command -v fail2ban-client &>/dev/null; then STATUS+=("installed (external)"); SELECTED+=(0); EXTERNAL+=(1)
else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

# 11: UFW
LABELS+=("UFW")
DESCRIPTIONS+=("Firewall (allow SSH + HTTP/S)")
if command -v ufw &>/dev/null; then STATUS+=("installed"); SELECTED+=(0); EXTERNAL+=(0); else STATUS+=(""); SELECTED+=(1); EXTERNAL+=(0); fi

_total=${#LABELS[@]}

# ========== Draw Menu ==========
draw_menu() {
  echo ""
  echo -e "${BOLD}${MAGENTA}╔══════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${MAGENTA}║            dotfiles installer — VPS              ║${NC}"
  echo -e "${BOLD}${MAGENTA}╚══════════════════════════════════════════════════╝${NC}"
  echo ""
  if [ "$_is_root" = "1" ]; then
    echo -e "  ${RED}${BOLD}⚠  Running as root!${NC}  ${DIM}It is strongly recommended to create a Custom User first.${NC}"
    echo ""
  elif [ "$_user_no_password" = "1" ]; then
    echo -e "  ${YELLOW}${BOLD}⚠  User '${USER}' has no password!${NC}  ${DIM}Enable the Custom User option to create a secure user.${NC}"
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
  echo -e "    ${DIM}• System update, Dotfiles repo${NC}"
  echo -e "    ${DIM}• Backup, Symlinks, Shell cleanup, Git config${NC}"
  echo -e "    ${DIM}• Zsh as default shell + bashrc fallback${NC}"
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
  # Dependency: dotfiles .zshrc requires Oh My Zsh (3) — must install with APT (1)
  [ "${SELECTED[1]}" = "1" ] && SELECTED[3]=1
  [ "${SELECTED[3]}" = "0" ] && SELECTED[1]=0
  # Dependency: AI CLI Tools (8) requires NVM (6) for npm
  [ "${SELECTED[8]}" = "1" ] && SELECTED[6]=1
  # Deselect NVM (6) → auto-deselect AI CLI Tools (8)
  [ "${SELECTED[6]}" = "0" ] && SELECTED[8]=0
done

# ========== Confirmation ==========
echo ""
echo -e "  ${BOLD}${MAGENTA}Will be installed:${NC}"
for (( i=0; i<_total; i++ )); do
  if [ "${SELECTED[$i]}" = "1" ]; then
    echo -e "    ${GREEN}+${NC} ${LABELS[$i]}  ${DIM}${DESCRIPTIONS[$i]}${NC}"
  fi
done
echo -e "    ${GREEN}+${NC} System update, Dotfiles, Symlinks  ${DIM}(always)${NC}"
echo ""

printf "  ${BOLD}${MAGENTA}Proceed with installation?${NC} [y/n]: "
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

# ========== System Update ==========
step "Updating system packages"
sudo apt update && sudo apt upgrade -y
done_msg "System updated"

# ========== Essential Tools ==========
step "Installing essential tools"
sudo apt install -y git curl wget unzip fontconfig software-properties-common
done_msg "Essential tools ready"

# ========== Dotfiles Repo ==========
step "Checking dotfiles repository"
DOTFILES_DIR="$HOME/.dotfiles"
DOTFILES_REPO="https://github.com/rifuki/dotfiles.git"

_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$_script_dir/.git" ] && git -C "$_script_dir" rev-parse --git-dir > /dev/null 2>&1; then
  if [ "$_script_dir" != "$DOTFILES_DIR" ]; then
    fail_msg "install.sh must be run from $HOME/.dotfiles"
    echo -e "    ${DIM}Found at: $_script_dir${NC}"
    echo -e "    ${DIM}1. curl -fsSL https://dotfiles.rifuki.dev/vps/install.sh | bash${NC}"
    echo -e "    ${DIM}2. mv $_script_dir $DOTFILES_DIR && bash $DOTFILES_DIR/install.sh${NC}"
    exit 1
  fi
  done_msg "Running from: $DOTFILES_DIR"
else
  if [ ! -d "$DOTFILES_DIR/.git" ]; then
    info_msg "Cloning dotfiles repo..."
    git clone --branch vps "$DOTFILES_REPO" "$DOTFILES_DIR"
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
for _f in "$HOME/.zshrc"; do
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
for _f in .zshrc; do
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

else
  # ========== Resume Mode: load pre-selected state ==========
  IFS=',' read -ra SELECTED <<< "$_RESUME_SEL"
  DOTFILES_DIR="$HOME/.dotfiles"
  DOTFILES_REPO="https://github.com/rifuki/dotfiles.git"
  echo ""
  echo -e "  ${BOLD}${CYAN}Resuming installation as $(whoami)...${NC}"
  echo ""
fi

# ══════════════════════════════════════════════════
#  SELECTED: Optional components
# ══════════════════════════════════════════════════

# ========== 0: Custom User ==========
if [ "${SELECTED[0]}" = "1" ]; then
  step "Setting up Custom User"
  printf "    Enter new username (leave empty to skip): "
  read -r _custom_user < /dev/tty
  if [ -z "$_custom_user" ]; then
    warn_msg "Custom user setup skipped"
  else
    # Create user if not exists
    if ! id "$_custom_user" &>/dev/null; then
      info_msg "Creating user $_custom_user..."
      sudo useradd -m -s /bin/bash "$_custom_user"
      done_msg "User $_custom_user created"
    else
      done_msg "User $_custom_user already exists"
    fi

    # Set password (retry on mismatch)
    info_msg "Set password for $_custom_user:"
    until sudo passwd "$_custom_user"; do
      warn_msg "Password mismatch or error — please try again"
    done
    done_msg "Password set"

    # Add to sudo group
    sudo usermod -aG sudo "$_custom_user"
    done_msg "Added $_custom_user to sudo group"

    # Copy SSH authorized_keys from current user
    _ssh_keys_copied=0
    if [ -f "$HOME/.ssh/authorized_keys" ]; then
      if confirm "Copy SSH authorized_keys from $USER to $_custom_user?"; then
        _new_ssh_dir="/home/$_custom_user/.ssh"
        sudo mkdir -p "$_new_ssh_dir"
        sudo cp "$HOME/.ssh/authorized_keys" "$_new_ssh_dir/authorized_keys"
        sudo chown -R "$_custom_user:$_custom_user" "$_new_ssh_dir"
        sudo chmod 700 "$_new_ssh_dir"
        sudo chmod 600 "$_new_ssh_dir/authorized_keys"
        done_msg "SSH authorized_keys copied to $_custom_user"
        _ssh_keys_copied=1
      fi
    else
      warn_msg "No authorized_keys found for $USER — SSH key copy skipped"
    fi

    # SSH hardening: only offered if SSH keys were actually copied
    if [ "$_ssh_keys_copied" = "1" ]; then
      if confirm "Require SSH key + password for $_custom_user? (AuthenticationMethods)"; then
        _sshd="/etc/ssh/sshd_config"
        # Enable PasswordAuthentication
        if sudo grep -q "^#\?PasswordAuthentication" "$_sshd" 2>/dev/null; then
          sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' "$_sshd"
        else
          echo "PasswordAuthentication yes" | sudo tee -a "$_sshd" > /dev/null
        fi
        # Append Match block only if not already present
        if ! sudo grep -q "^Match User $_custom_user$" "$_sshd" 2>/dev/null; then
          printf '\nMatch User %s\n    PasswordAuthentication yes\n    AuthenticationMethods publickey,password\n' "$_custom_user" | sudo tee -a "$_sshd" > /dev/null
        fi
        # Validate config then restart
        if sudo sshd -t 2>/dev/null; then
          sudo systemctl restart sshd 2>/dev/null || sudo service ssh restart 2>/dev/null || true
          done_msg "SSH: requires publickey + password for $_custom_user"
        else
          warn_msg "sshd config test failed — manual check needed: sudo sshd -t"
        fi
      fi
    else
      # No keys copied — enable PasswordAuthentication so user can at least login via password
      warn_msg "No SSH keys copied — enabling PasswordAuthentication so $_custom_user can login via password"
      _sshd="/etc/ssh/sshd_config"
      if sudo grep -q "^#\?PasswordAuthentication" "$_sshd" 2>/dev/null; then
        sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' "$_sshd"
      else
        echo "PasswordAuthentication yes" | sudo tee -a "$_sshd" > /dev/null
      fi
      if sudo sshd -t 2>/dev/null; then
        sudo systemctl restart sshd 2>/dev/null || sudo service ssh restart 2>/dev/null || true
        done_msg "PasswordAuthentication enabled — login: ssh $_custom_user@<your-server>"
      else
        warn_msg "sshd config test failed — manual check needed: sudo sshd -t"
      fi
    fi

    done_msg "Custom user $_custom_user is ready"
    info_msg "Login: ssh $_custom_user@<your-server>"

    # Auto-lock all passwordless default cloud users (no per-user prompt)
    _cloud_defaults=(ubuntu azureuser ec2-user admin centos fedora debian cloud)
    for _default_user in "${_cloud_defaults[@]}"; do
      if id "$_default_user" &>/dev/null && [ "$_default_user" != "$_custom_user" ]; then
        _pw_status=$(sudo passwd -S "$_default_user" 2>/dev/null | awk '{print $2}' || true)
        _pw_empty=0
        if [ "$_pw_status" = "P" ]; then
          _pw_hash=$(sudo getent shadow "$_default_user" 2>/dev/null | cut -d: -f2 || true)
          case "$_pw_hash" in
            ""|"!"*|"*"|"!!"*) _pw_empty=1 ;;
          esac
        else
          _pw_empty=1
        fi
        if [ "$_pw_empty" = "1" ]; then
          sudo passwd -l "$_default_user" 2>/dev/null && \
            done_msg "Locked passwordless user: $_default_user" || true
        fi
      fi
    done

    # If other components selected, prompt: re-launch as new user or continue here
    _other_sel=0
    for (( _i=1; _i<${#SELECTED[@]}; _i++ )); do
      [ "${SELECTED[$_i]}" = "1" ] && _other_sel=1 && break
    done

    if [ "$_other_sel" = "1" ]; then
      echo ""
      echo -e "  ${BOLD}${MAGENTA}╔══════════════════════════════════════════════════╗${NC}"
      echo -e "  ${BOLD}${MAGENTA}║       ⚠  Where should components install?        ║${NC}"
      echo -e "  ${BOLD}${MAGENTA}╚══════════════════════════════════════════════════╝${NC}"
      echo ""
      echo -e "    ${BOLD}${CYAN}[1]${NC} Re-launch as ${BOLD}${CYAN}$_custom_user${NC}  ${GREEN}← recommended${NC}"
      echo -e "        ${DIM}→ NVM, dotfiles, zsh, etc. install into $_custom_user's \$HOME${NC}"
      echo ""
      echo -e "    ${BOLD}${YELLOW}[2]${NC} Continue as ${BOLD}${YELLOW}$USER${NC}  ${RED}← not recommended${NC}"
      echo -e "        ${DIM}→ All apps install in $USER's \$HOME, not in $_custom_user's${NC}"
      echo -e "        ${RED}▸ $_custom_user will NOT have these apps set up${NC}"
      echo ""
      while true; do
        printf "  > "
        read -r _launch_choice < /dev/tty
        case "$_launch_choice" in
          1)
            _new_home=$(getent passwd "$_custom_user" | cut -d: -f6)
            if [ ! -d "$_new_home/.dotfiles/.git" ]; then
              info_msg "Cloning dotfiles for $_custom_user..."
              sudo -u "$_custom_user" git clone --branch vps "$DOTFILES_REPO" "$_new_home/.dotfiles" 2>/dev/null || \
                { sudo cp -r "$DOTFILES_DIR" "$_new_home/.dotfiles" && \
                  sudo chown -R "$_custom_user:$_custom_user" "$_new_home/.dotfiles"; }
              done_msg "Dotfiles ready for $_custom_user"
            fi
            _sel_str="0"
            for (( _i=1; _i<${#SELECTED[@]}; _i++ )); do
              _sel_str+=",${SELECTED[$_i]}"
            done
            echo ""
            step "Re-launching installer as $_custom_user"
            info_msg "All remaining components will install under $_custom_user's home"
            exec sudo -H -u "$_custom_user" bash "$_new_home/.dotfiles/install.sh" --resume "$_sel_str"
            ;;
          2)
            echo ""
            echo -e "  ${RED}${BOLD}╔══════════════════════════════════════════════════╗${NC}"
            echo -e "  ${RED}${BOLD}║  ⚠  WARNING: Continuing as $USER                 ║${NC}"
            echo -e "  ${RED}${BOLD}╚══════════════════════════════════════════════════╝${NC}"
            echo -e "  ${RED}▸ All selected apps will install in $USER's \$HOME${NC}"
            echo -e "  ${RED}▸ $_custom_user will NOT have these tools in their environment${NC}"
            echo -e "  ${RED}▸ Re-run install.sh as $_custom_user later to set up properly${NC}"
            echo ""
            _WARN_WRONG_USER=1
            break
            ;;
          *)
            echo -e "  ${YELLOW}Enter 1 or 2${NC}"
            ;;
        esac
      done
    fi
  fi
fi

if [ "${_WARN_WRONG_USER:-0}" = "1" ]; then
  echo -e "  ${RED}${BOLD}⚠  Installing as $USER — these apps will NOT appear in the new custom user's home${NC}"
  echo ""
fi

# ========== 1: APT Packages + Nerd Font ==========
if [ "${SELECTED[1]}" = "1" ]; then
  step "Installing APT packages + Nerd Font"

  # Neovim: latest stable from GitHub releases
  if ! command -v nvim &>/dev/null; then
    info_msg "Installing Neovim (latest stable)..."
    _nvim_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
    curl -fsSL "$_nvim_url" -o /tmp/nvim.tar.gz
    sudo tar -xzf /tmp/nvim.tar.gz -C /opt/
    sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
    rm -f /tmp/nvim.tar.gz
    done_msg "Neovim installed"
  else
    done_msg "Neovim already installed: $(nvim --version | head -1)"
  fi

  # Standard apt packages
  _apt_pkgs=("tmux" "zsh" "htop" "ripgrep" "neofetch")
  for _pkg in "${_apt_pkgs[@]}"; do
    if ! dpkg -s "$_pkg" &>/dev/null; then
      info_msg "Installing ${_pkg}..."
      sudo apt install -y "$_pkg"
      done_msg "${_pkg} installed"
    else
      done_msg "${_pkg} already installed"
    fi
  done

  # yazi: download binary from GitHub releases
  if ! command -v yazi &>/dev/null; then
    info_msg "Installing yazi..."
    _yazi_url=$(curl -fsSL https://api.github.com/repos/sxyazi/yazi/releases/latest | grep -o '"browser_download_url": "[^"]*x86_64-unknown-linux-gnu.zip"' | cut -d'"' -f4)
    if [ -n "$_yazi_url" ]; then
      curl -fsSL "$_yazi_url" -o /tmp/yazi.zip
      unzip -qo /tmp/yazi.zip -d /tmp/yazi-extract
      sudo mv /tmp/yazi-extract/yazi-x86_64-unknown-linux-gnu/yazi /usr/local/bin/yazi
      sudo chmod +x /usr/local/bin/yazi
      rm -rf /tmp/yazi.zip /tmp/yazi-extract
      done_msg "yazi installed"
    else
      warn_msg "Could not find yazi release URL"
    fi
  else
    done_msg "yazi already installed"
  fi

  # gh: GitHub CLI via official apt repo
  if ! command -v gh &>/dev/null; then
    info_msg "Installing GitHub CLI..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install -y gh
    done_msg "GitHub CLI installed"
  else
    done_msg "GitHub CLI already installed"
  fi

  # JetBrainsMono Nerd Font
  if ! ls "$HOME/.local/share/fonts/JetBrainsMono"*"NerdFont"* &>/dev/null 2>&1; then
    info_msg "Installing JetBrainsMono Nerd Font..."
    _font_url=$(curl -fsSL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | grep -o '"browser_download_url": "[^"]*JetBrainsMono.zip"' | cut -d'"' -f4)
    if [ -n "$_font_url" ]; then
      mkdir -p "$HOME/.local/share/fonts"
      curl -fsSL "$_font_url" -o /tmp/JetBrainsMono.zip
      unzip -qo /tmp/JetBrainsMono.zip -d "$HOME/.local/share/fonts/"
      fc-cache -fv > /dev/null 2>&1
      rm -f /tmp/JetBrainsMono.zip
      done_msg "JetBrainsMono Nerd Font installed"
    else
      warn_msg "Could not find font release URL"
    fi
  else
    done_msg "JetBrainsMono Nerd Font already installed"
  fi
fi

# ========== 2: Starship ==========
if [ "${SELECTED[2]}" = "1" ]; then
  step "Installing Starship"
  if ! command -v starship &>/dev/null; then
    info_msg "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    done_msg "Starship installed"
  else
    done_msg "Starship already installed: $(starship --version | head -1)"
  fi
fi

# ========== 3: Oh My Zsh ==========
if [ "${SELECTED[3]}" = "1" ]; then
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

# ========== 4: Rust ==========
if [ "${SELECTED[4]}" = "1" ]; then
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

# ========== 5: Bun ==========
if [ "${SELECTED[5]}" = "1" ]; then
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

# ========== 6: NVM + Node ==========
if [ "${SELECTED[6]}" = "1" ]; then
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

# ========== 7: Docker ==========
if [ "${SELECTED[7]}" = "1" ]; then
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

# ========== 8: AI CLI Tools ==========
if [ "${SELECTED[8]}" = "1" ]; then
  step "Installing AI CLI Tools"
  # Ensure npm is available
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  if ! command -v npm &>/dev/null; then
    warn_msg "npm not found — NVM/Node required for AI CLI Tools"
  else
    if ! command -v claude &>/dev/null; then
      info_msg "Installing Claude Code..."
      npm install -g @anthropic-ai/claude-code
      done_msg "Claude Code installed"
    else
      done_msg "Claude Code already installed"
    fi
    if ! command -v gemini &>/dev/null; then
      info_msg "Installing Gemini CLI..."
      npm install -g @google/gemini-cli
      done_msg "Gemini CLI installed"
    else
      done_msg "Gemini CLI already installed"
    fi
  fi
  # Claude statusline
  mkdir -p "$HOME/.claude"
  if [ -f "$DOTFILES_DIR/.claude/statusline-command.sh" ]; then
    ln -sf "$DOTFILES_DIR/.claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
    done_msg "~/.claude/statusline-command.sh"
  fi
fi

# ========== 9: Swap ==========
if [ "${SELECTED[9]}" = "1" ]; then
  step "Setting up 2GB swap"
  if [ ! -f /swapfile ]; then
    info_msg "Creating 2GB swap file..."
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab > /dev/null
    done_msg "2GB swap created and enabled"
  else
    done_msg "Swap file already exists"
  fi
fi

# ========== 10: fail2ban ==========
if [ "${SELECTED[10]}" = "1" ]; then
  step "Installing fail2ban"
  if ! command -v fail2ban-client &>/dev/null; then
    info_msg "Installing fail2ban..."
    sudo apt install -y fail2ban
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban
    done_msg "fail2ban installed and enabled"
  else
    done_msg "fail2ban already installed"
  fi
fi

# ========== 11: UFW ==========
if [ "${SELECTED[11]}" = "1" ]; then
  step "Setting up UFW firewall"
  if ! command -v ufw &>/dev/null; then
    info_msg "Installing UFW..."
    sudo apt install -y ufw
  fi
  sudo ufw allow OpenSSH
  sudo ufw allow 80/tcp
  sudo ufw allow 443/tcp
  echo "y" | sudo ufw enable
  done_msg "UFW enabled (SSH + HTTP/S allowed)"
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
rm -f "$HOME/.zshrc"
mkdir -p "$HOME/.config"
for _d in "$REPO_DIR/.config"/*/; do
  _name="$(basename "$_d")"
  ln -sf "$REPO_DIR/.config/$_name" "$HOME/.config/$_name"
  done_msg "~/.config/$_name"
done
ln -sf "$REPO_DIR/.zshrc" "$HOME/.zshrc"
done_msg "~/.zshrc"

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
    warn_msg "zsh not installed, skipping"
  fi
fi

# ========== Done ==========
echo ""
echo -e "${BOLD}${MAGENTA}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${MAGENTA}║           ✓ Installation complete!               ║${NC}"
echo -e "${BOLD}${MAGENTA}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${DIM}👉 Restart your terminal or run: exec zsh${NC}"
echo ""
