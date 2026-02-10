# ========== Oh My Zsh ==========
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

# ========== Editor ==========
export EDITOR=nvim

# ========== NVM (Node Version Manager) ==========
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ========== Bun ==========
export PATH="$HOME/.bun/bin:$PATH"

# ========== Local Bin ==========
export PATH="$HOME/.local/bin:$PATH"

# ========== Docker CLI Completions ==========
fpath=(/Users/rifuki/.docker/completions $fpath)
autoload -Uz compinit
compinit

# ========== C/C++ Development ==========
export CPATH="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include:$CPATH"

# ========== Aliases ==========
alias n='nvim'
alias fucking='sudo'
alias rm='trash'
