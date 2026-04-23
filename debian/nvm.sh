#!/bin/bash
# nvm.sh — Standalone NVM migration helper for Debian/Linux
#
# Usage:
#   Install NVM:   bash ~/.dotfiles/debian/nvm.sh install
#   Uninstall NVM: bash ~/.dotfiles/debian/nvm.sh uninstall
#   Status:        bash ~/.dotfiles/debian/nvm.sh status
#
# This script is intentionally kept separate from install.sh and uninstall.sh.
# The main setup (install.sh) uses Mise to manage Node instead of NVM.
# Use this script only for machines that still need NVM or to migrate away from it.

set -e

GREEN='\\033[38;2;80;250;123m'
MAGENTA='\\033[38;2;255;121;198m'
PEACH='\\033[38;2;240;202;164m'
CYAN='\\033[38;2;0;217;255m'
RED='\\033[38;2;255;85;85m'
BOLD='\\033[1m'
DIM='\\033[2m'
NC='\\033[0m'

NVM_VERSION="v0.40.3"
NVM_DIR="$HOME/.nvm"

step()     { echo -e "\n${BOLD}${MAGENTA}  ◆ $1${NC}"; }
done_msg() { echo -e "  ${GREEN}✔${NC} $1"; }
warn_msg() { echo -e "  ${PEACH}▸${NC} $1"; }
err_msg()  { echo -e "  ${RED}✗${NC} $1"; }

_status() {
  echo ""
  if [ -d "$NVM_DIR" ]; then
    echo -e "  ${GREEN}✔${NC} NVM is installed at ${CYAN}$NVM_DIR${NC}"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
      # shellcheck disable=SC1090
      \. "$NVM_DIR/nvm.sh"
      echo -e "  ${GREEN}✔${NC} NVM version: $(nvm --version 2>/dev/null)"
      echo -e "  ${DIM}  Installed Node versions:${NC}"
      nvm ls 2>/dev/null | sed 's/^/    /'
    fi
  else
    echo -e "  ${DIM}  NVM is not installed (~/.nvm not found)${NC}"
  fi
  echo ""
}

_install() {
  step "Installing NVM $NVM_VERSION"
  if [ -d "$NVM_DIR" ] && [ -s "$NVM_DIR/nvm.sh" ]; then
    done_msg "NVM already installed at $NVM_DIR"
  else
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | PROFILE=/dev/null bash
    done_msg "NVM installed"
  fi

  # Source nvm in current session
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  step "Installing Node.js LTS via NVM"
  if nvm ls --no-colors 2>/dev/null | grep -q "lts"; then
    done_msg "Node LTS already installed: $(node --version 2>/dev/null)"
  else
    nvm install --lts
    done_msg "Node LTS installed: $(node --version 2>/dev/null)"
  fi
  nvm alias default lts/*

  echo ""
  warn_msg "NVM is installed but NOT added to .zshrc automatically."
  warn_msg "To activate NVM in your shell, add the following to ~/.zshrc manually:"
  echo ""
  echo -e "  ${DIM}export NVM_DIR=\"\$HOME/.nvm\""
  echo -e "  [ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\""
  echo -e "  [ -s \"\$NVM_DIR/bash_completion\" ] && \\. \"\$NVM_DIR/bash_completion\"${NC}"
  echo ""
  warn_msg "Note: Adding NVM to .zshrc will slow down terminal startup significantly."
  warn_msg "Consider using 'mise use node@<version>' per-project instead."
  echo ""
}

_uninstall() {
  step "Uninstalling NVM"
  if [ ! -d "$NVM_DIR" ]; then
    done_msg "NVM is not installed — nothing to remove"
    return
  fi

  echo -e "  ${DIM}Removing $NVM_DIR ...${NC}"
  rm -rf "$NVM_DIR"
  done_msg "~/.nvm removed"

  # Clean up any nvm lines injected by the installer into shell profiles
  for _f in "$HOME/.zprofile" "$HOME/.zshenv" "$HOME/.profile" "$HOME/.bash_profile" "$HOME/.bashrc"; do
    [ -f "$_f" ] || continue
    grep -qE 'NVM_DIR|nvm\.sh|bash_completion.*nvm' "$_f" 2>/dev/null || continue
    grep -vE 'NVM_DIR|nvm\.sh|bash_completion.*nvm|Added by nvm installer' "$_f" > "${_f}.tmp" || true
    if [ -s "${_f}.tmp" ]; then
      mv "${_f}.tmp" "$_f"
    else
      rm -f "${_f}.tmp" "$_f"
    fi
    done_msg "Cleaned nvm entries from $(basename "$_f")"
  done

  echo ""
  warn_msg "If you had NVM lines in ~/.zshrc, remove them manually."
  warn_msg "Then run: exec zsh"
  echo ""
}

case "${1:-status}" in
  install)   _install   ;;
  uninstall) _uninstall ;;
  status)    _status    ;;
  *)
    echo -e "\n  Usage: $(basename "$0") {install|uninstall|status}\n"
    exit 1
    ;;
esac
