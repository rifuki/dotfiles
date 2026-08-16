# ── Environment ──────────────────────
[ -f "/opt/homebrew/bin/brew" ] && eval "$(/opt/homebrew/bin/brew shellenv zsh)"

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"

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

# ── Terminal Recovery ─────────────────
__reset_terminal_mouse_modes() {
  [[ -n "$TMUX" ]] && return
  printf '\033[?1000l\033[?1002l\033[?1003l\033[?1005l\033[?1006l\033[?1015l\033[?1004l' > /dev/tty 2>/dev/null || true
}
precmd_functions+=(__reset_terminal_mouse_modes)

fixterm() {
  printf '\033[?1000l\033[?1002l\033[?1003l\033[?1005l\033[?1006l\033[?1015l\033[?1004l\033[?2004l\033[?25h' > /dev/tty 2>/dev/null || true
  stty sane 2>/dev/null || true
  clear
}

# ── Starship ──────────────────────────
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
eval "$(starship init zsh)"

# ─── AI Tools Configuration ─────────────────────────────────────────────────
# [ -f "$HOME/.dotfiles/macos/ai-tools.sh" ] && source "$HOME/.dotfiles/macos/ai-tools.sh"

# ─── Local Secrets ───────────────────────────────────────────────────────────
# [ -f "$HOME/.secrets.sh" ] && source "$HOME/.secrets.sh"

export PATH="$HOME/.browser-use-env/bin:$PATH"

# Added by Windsurf
export PATH="/Users/rifuki/.codeium/windsurf/bin:$PATH"



export PATH="/Users/rifuki/.local/bin:$PATH"
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"

export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"

export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

# Machine-local overrides: accounts, private paths, per-host tweaks.
# Never committed — create ~/.zshrc.local on each machine as needed.
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
