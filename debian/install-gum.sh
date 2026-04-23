#!/bin/bash
set -e

# ========== Colors (Miku Cyberpunk Theme) ==========
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

# ========== Install gum if not present ==========
if ! command -v gum &>/dev/null; then
  echo -e "${CYAN}Installing gum for interactive menu...${NC}"
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
  echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
  sudo apt update && sudo apt install -y gum
  echo -e "${GREEN}✔ gum installed${NC}\n"
fi

# ========== Header ==========
clear
gum style \
  --foreground 0 --background 0 \
  --border double --border-foreground 0 \
  --align center --width 60 --margin "1 0" \
  "$(gum style --foreground 0 'dotfiles installer — Debian')"

# ========== Detect environment ==========
_is_root=0; [ "$EUID" -eq 0 ] && _is_root=1
_user_no_password=0
if [ "$_is_root" = "0" ] && ! sudo -n true 2>/dev/null; then
  if ! passwd -S "$USER" 2>/dev/null | grep -qE "^$USER P"; then
    _user_no_password=1
  fi
fi

# ========== Build options ==========
OPTIONS=()
DESCRIPTIONS=()

# 1. APT Packages
_apt_status="not installed"
_apt_count=0
for _pkg in build-essential tmux zsh htop ripgrep fzf imagemagick gh lua5.4; do
  dpkg -s "$_pkg" &>/dev/null 2>&1 && ((_apt_count++))
done
command -v neofetch &>/dev/null && ((_apt_count++))
command -v yazi &>/dev/null && ((_apt_count++))
[ "$_apt_count" -gt 0 ] && _apt_status="$_apt_count/13 installed"
OPTIONS+=("APT Packages + Nerd Font ($_apt_status)")
DESCRIPTIONS+=("neovim, tmux, zsh, htop, ripgrep, neofetch, yazi, fzf, imagemagick, gh, lua5.4, JetBrainsMono")

# 2. Starship
command -v starship &>/dev/null && _starship_status="installed" || _starship_status=""
OPTIONS+=("Starship ${_starship_status:+($_starship_status)}")
DESCRIPTIONS+=("Cross-shell prompt theme")

# 3. Oh My Zsh
[ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ] && _omz_status="installed" || _omz_status=""
OPTIONS+=("Oh My Zsh ${_omz_status:+($_omz_status)}")
DESCRIPTIONS+=("Zsh framework + plugins")

# 4. Rust
command -v rustc &>/dev/null && _rust_status="installed" || _rust_status=""
OPTIONS+=("Rust ${_rust_status:+($_rust_status)}")
DESCRIPTIONS+=("Rust toolchain via rustup")

# 5. Bun
[ -d "$HOME/.bun" ] && _bun_status="installed" || _bun_status=""
OPTIONS+=("Bun ${_bun_status:+($_bun_status)}")
DESCRIPTIONS+=("JavaScript runtime")

# 6. Node 24
command -v mise &>/dev/null && mise list node 2>/dev/null | grep -q "24" && _node_status="installed" || _node_status=""
OPTIONS+=("Node 24 (via Mise) ${_node_status:+($_node_status)}")
DESCRIPTIONS+=("Node.js via Mise")

# 7. Docker
command -v docker &>/dev/null && _docker_status="installed" || _docker_status=""
OPTIONS+=("Docker ${_docker_status:+($_docker_status)}")
DESCRIPTIONS+=("Container engine")

# 8. Swap
[ -f /swapfile ] && _swap_status="active" || _swap_status=""
OPTIONS+=("Swap (2GB) ${_swap_status:+($_swap_status)}")
DESCRIPTIONS+=("Create 2GB swap file")

# 9. fail2ban
command -v fail2ban-client &>/dev/null && _f2b_status="installed" || _f2b_status=""
OPTIONS+=("fail2ban ${_f2b_status:+($_f2b_status)}")
DESCRIPTIONS+=("Intrusion prevention")

# 10. UFW
command -v ufw &>/dev/null && _ufw_status="installed" || _ufw_status=""
OPTIONS+=("UFW ${_ufw_status:+($_ufw_status)}")
DESCRIPTIONS+=("Firewall (allow SSH + HTTP/S)")

# ========== Interactive selection ==========
gum style --foreground 0 --bold "Select components to install:"
echo ""

SELECTED=$(gum choose --no-limit --height 15 --cursor.foreground="0" --selected.foreground="0" "${OPTIONS[@]}")

if [ -z "$SELECTED" ]; then
  echo -e "\n${YELLOW}⏭️  No components selected. Exiting.${NC}"
  exit 0
fi

# ========== Confirmation ==========
echo ""
gum style --foreground 0 --bold "Will be installed:"
echo "$SELECTED" | while read -r line; do
  echo -e "  ${GREEN}+${NC} $line"
done
echo -e "  ${GREEN}+${NC} ${DIM}System update, Dotfiles, Symlinks (always)${NC}"
echo ""

gum confirm "Proceed with installation?" || {
  echo -e "\n${YELLOW}⏭️  Installation cancelled.${NC}"
  exit 0
}

# ========== Installation ==========
echo ""
step "Starting installation..."

# TODO: Map selected items to actual installation logic
# For now, just show what would be installed
echo "$SELECTED" | while read -r item; do
  done_msg "Would install: $item"
done

echo ""
gum style \
  --foreground 0 --background 0 \
  --border double --border-foreground 0 \
  --align center --width 60 --margin "1 0" \
  "$(gum style --foreground 0 '✓ Installation complete!')"
