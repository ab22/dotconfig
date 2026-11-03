# Brew
eval "$(/opt/homebrew/bin/brew shellenv)"
autoload -Uz compinit && compinit

# brew shellenv prepends /opt/homebrew/bin, landing it ahead of the mise shims that
# ~/.zshenv prepended (.zshenv is sourced before this file). That shadows repo-pinned
# toolchains with Homebrew's — e.g. `go` resolving to brew's 1.26.5 while GOROOT points
# at mise's 1.26.3, which breaks builds with a compile/go-tool version mismatch.
# Re-prepend so mise wins. Keep this after brew shellenv.
export PATH="$HOME/.local/share/mise/shims:$PATH"

# Set vi mode
set -o vi
bindkey -M vicmd '/' history-incremental-search-backward
bindkey -M vicmd '?' history-incremental-search-forward

# Custom aliases
alias vim=nvim
alias ls='ls --color=auto'
alias gbc='git branch --show-current | tr -d "\n" | pbcopy'
# Set Powerlevel10k theme.
source ~/code/powerlevel10k/powerlevel10k.zsh-theme
# Golang
export PATH=$PATH:/usr/local/go/bin
export GOPATH=~/go
export GOBIN=$GOPATH/bin
export PATH=$PATH:$GOBIN
# Rust
export PATH=$PATH:~/.cargo/bin
# Other
export DOCKER_HOST="unix://$HOME/.docker/run/docker.sock"

# agent-toolkit binaries (gh-plan, plan, preflight, handoff, dod)
export PATH="$PATH:$HOME/.local/bin"

# Neovim
# export PATH=$PATH:/opt/nvim-linux64/bin
# NvChad trial — isolated under NVIM_APPNAME so plain `nvim` keeps its config.
alias nvchad='NVIM_APPNAME=nvim-nvchad nvim'

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Set up python venv
[[ -f ~/.venv/bin/activate ]] && source ~/.venv/bin/activate
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# NVM auto-generated file.
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# Load Angular CLI autocompletion.
# source <(ng completion script)

# man configuration variables.
export MANPAGER='nvim +Man!'
export MANWIDTH=90

# Load direnv automatically
eval "$(direnv hook zsh)"
eval "$(task --completion zsh)"
export PATH=/opt/homebrew/opt/libpq/bin:$PATH

eval "$(/Users/abe/.local/bin/mise activate zsh)"
