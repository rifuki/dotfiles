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
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"
export PATH="$HOME/.yarn/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="/usr/local/go/bin:$PATH"
export PATH="/opt/homebrew/opt/python@3.12/bin:$PATH"
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"

# ── Tools ──────────────────────────────────────────────────────────────────────
export NARGO_HOME="$HOME/.nargo"
export PATH="$PATH:$NARGO_HOME/bin"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

export CPATH="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include:$CPATH"

# Docker CLI completions
fpath=(/Users/rifuki/.docker/completions $fpath)
autoload -Uz compinit
compinit

# ── Aliases ──────────────────────────────────────────────────────────────────── alias n='nvim'
alias fucking='sudo'
alias rm='trash'
