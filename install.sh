#!/usr/bin/env bash
set -euo pipefail

CYAN='\033[38;2;0;217;255m'
GREEN='\033[38;2;80;250;123m'
MAGENTA='\033[38;2;255;121;198m'
RED='\033[38;2;255;85;85m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

_os="$(uname)"
_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo -e "${BOLD}${MAGENTA}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${MAGENTA}║              dotfiles installer                  ║${NC}"
echo -e "${BOLD}${MAGENTA}╚══════════════════════════════════════════════════╝${NC}"
echo ""

if [[ "$_os" == "Darwin" ]]; then
  echo -e "  ${GREEN}✔${NC} Detected: ${BOLD}${CYAN}macOS${NC}"
  echo -e "  ${DIM}→ Running macos/install.sh${NC}"
  echo ""
  exec "$_script_dir/macos/install.sh" "$@"
elif [[ "$_os" == "Linux" ]]; then
  echo -e "  ${GREEN}✔${NC} Detected: ${BOLD}${CYAN}Linux${NC}"
  echo -e "  ${DIM}→ Running vps/install.sh${NC}"
  echo ""
  exec "$_script_dir/vps/install.sh" "$@"
else
  echo -e "  ${RED}✖${NC} Unsupported OS: ${BOLD}$_os${NC}"
  echo -e "  ${DIM}Supported: macOS (Darwin), Linux (Ubuntu/Debian)${NC}"
  echo ""
  exit 1
fi
