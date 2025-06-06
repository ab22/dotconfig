# Brew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Set vi mode
set -o vi
bindkey -M vicmd '/' history-incremental-search-backward
bindkey -M vicmd '?' history-incremental-search-forward

# Custom aliases
alias vim=nvim
alias ls='ls --color=auto'
# Set Powerlevel10k theme.
source ~/code/powerlevel10k/powerlevel10k.zsh-theme
# Golang
export PATH=$PATH:/usr/local/go/bin
export GOPATH=~/go
export GOBIN=$GOPATH/bin
export PATH=$PATH:$GOBIN
# Rust
export PATH=$PATH:~/.cargo/bin

# Neovim
# export PATH=$PATH:/opt/nvim-linux64/bin

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Set up python venv
# [[ -f ~/.venv/bin/activate ]] && source ~/.venv/bin/activate
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# NVM auto-generated file.
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Load Angular CLI autocompletion.
# source <(ng completion script)

# man configuration variables.
export MANPAGER='nvim +Man!'
export MANWIDTH=90
