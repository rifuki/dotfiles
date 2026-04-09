# ── Environment ──────────────────────
[ -f "/opt/homebrew/bin/brew" ] && eval "$(/opt/homebrew/bin/brew shellenv zsh)"

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

export EDITOR=nvim
export CPATH="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include:$CPATH"

# ── Completions ───────────────────────
# Must be registered before OMZ loads (OMZ calls compinit internally)
fpath=($HOME/.docker/completions $fpath)

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
    zsh-wakatime
)

source $ZSH/oh-my-zsh.sh

# ── Tools ─────────────────────────────
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Mise: per-project Node override via .mise.toml or .nvmrc
command -v mise &>/dev/null && eval "$(mise activate zsh)"

# ── Aliases ───────────────────────────
alias n='nvim'
alias fucking='sudo'

rm() {
  if command -v trash &>/dev/null; then
    local -a paths
    for arg in "$@"; do
      [[ "$arg" == -* ]] || paths+=("$arg")
    done
    trash "${paths[@]}"
  else
    command rm -i "$@"
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

# ─── AI Tools Configuration ─────────────────────────────────────────────────
# [ -f "$HOME/.dotfiles/macos/ai-tools.sh" ] && source "$HOME/.dotfiles/macos/ai-tools.sh"

# ─── Local Secrets ───────────────────────────────────────────────────────────
[ -f "$HOME/.secrets.sh" ] && source "$HOME/.secrets.sh"

# Added by Antigravity
export PATH="/Users/rifuki/.antigravity/antigravity/bin:$PATH"

export PATH="$HOME/.browser-use-env/bin:$PATH"
