# Git for Windows (git-bash) setup — the Windows counterpart of
# root/{macos,archlinux}/.zshrc. Bash has no zsh plugin layer, so this stays
# within what actually exists on Windows: PATH, aliases, and tool hooks.
# Anything optional is guarded so a fresh machine still opens a clean shell.
#
# Loaded from ~/.bash_profile, which the login shell git-bash starts reads.

# Rust (rustup)
export PATH="$PATH:$HOME/.cargo/bin"

# agent-toolkit binaries (gh-plan, plan, preflight, handoff, dod)
export PATH="$PATH:$HOME/.local/bin"

# Neovim ships with Git for Windows' sibling tools at /c/Program Files/Neovim
# (already on the system PATH); plain `nvim` keeps its config and the NvChad
# trial runs under NVIM_APPNAME so the two never share state.
alias vim=nvim
alias nvchad='NVIM_APPNAME=nvim-nvchad nvim'
alias ls='ls --color=auto'

# man pages through Neovim
export MANPAGER='nvim +Man!'
export MANWIDTH=90

# go-task completion (task is installed via npm on this machine)
command -v task >/dev/null 2>&1 && eval "$(task --completion bash)"

# direnv
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook bash)"
