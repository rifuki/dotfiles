# ── Oh My Zsh ─────────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="spaceship"

plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    spaceship-ember
    spaceship-vi-mode
)

source $ZSH/oh-my-zsh.sh

# ── Editor ─────────────────────────────────────────────────────────────────────
export EDITOR=nvim

# ── PATH ───────────────────────────────────────────────────────────────────────
# Homebrew (Apple Silicon)
[ -f "/opt/homebrew/bin/brew" ] && eval "$(/opt/homebrew/bin/brew shellenv zsh)"

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

export CPATH="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include:$CPATH"

# Docker CLI completions
fpath=(/Users/rifuki/.docker/completions $fpath)
autoload -Uz compinit
compinit

# ── Aliases ────────────────────────────────────────────────────────────────────
alias n='nvim'
alias fucking='sudo'
alias rm='trash'

# bun completions
[ -s "/Users/rifuki/.bun/_bun" ] && source "/Users/rifuki/.bun/_bun"
