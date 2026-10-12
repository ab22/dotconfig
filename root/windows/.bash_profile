# Git for Windows starts a login shell for every new terminal, and a login shell
# reads ~/.bash_profile — never ~/.bashrc. Git for Windows generates this file
# itself when ~/.bashrc exists without it, so this is the same hop, kept in the
# repo instead: the real setup lives in ~/.bashrc, where interactive
# non-login shells (e.g. `bash -c`) find it too.

# POSIX fallback, as in Git for Windows' own generated file.
if [ -f ~/.profile ]; then . ~/.profile; fi
if [ -f ~/.bashrc ]; then . ~/.bashrc; fi
