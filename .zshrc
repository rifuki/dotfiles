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
  trash "${paths[@]}"
}

# ── Starship ──────────────────────────
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
eval "$(starship init zsh)"
