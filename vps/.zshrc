# ── Environment ──────────────────────
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

export EDITOR=nvim

# ── Oh My Zsh ─────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""

# Syntax highlighting styles (must be set before plugin loads)
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[default]='fg=#FFFFFF'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=#00D9FF,bold'
ZSH_HIGHLIGHT_STYLES[command]='fg=#00D9FF,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=#00D9FF,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#BD93F9,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#01CBC6,bold'
ZSH_HIGHLIGHT_STYLES[path]='fg=#FFB86C'

plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# ── Tools ─────────────────────────────
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# ── Aliases ───────────────────────────
alias n='nvim'
alias fucking='sudo'

rm() {
  local -a paths
  for arg in "$@"; do
    [[ "$arg" == -* ]] || paths+=("$arg")
  done
  if command -v trash-put &>/dev/null; then
    trash-put "${paths[@]}"
  else
    command rm -i "${paths[@]}"
  fi
}

# ── Yazi ──────────────────────────────
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  local cwd="$(cat -- "$tmp")"
  [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

# ── Starship ──────────────────────────
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
eval "$(starship init zsh)"
