#!/usr/bin/env bash
#
# Print the dotconfig platform id for this machine:
#   macos | archlinux | linux | windows
#
# The id names the matching directory under root/ (root/<id>/) and is what
# scripts/gen.sh and scripts/link.sh default to when no argument is given.
#
# `archlinux` is an Arch-based desktop (zsh, sway autostart, rofi themes).
# `linux` is any other distribution — a dev box, a server, WSL — which gets the
# editor configs and the agent files but no desktop/shell profile, because
# root/archlinux/.zprofile would autostart sway. Add a root/linux/ tree to give
# it one.
#
# `windows` means Git for Windows (git-bash/MSYS), which is the shell the
# Windows scripts run under. WSL reports Linux and is treated as `linux`.
#
set -euo pipefail

case "$(uname -s)" in
  Darwin)
    echo macos
    exit 0
    ;;
  MINGW*|MSYS*|CYGWIN*)
    echo windows
    exit 0
    ;;
  Linux)
    if [ -r /etc/os-release ] && grep -qiE '^(ID|ID_LIKE)="?([a-z]+ )*arch' /etc/os-release; then
      echo archlinux
    else
      echo linux
    fi
    exit 0
    ;;
esac

echo "detect-os: unsupported operating system: $(uname -s)" >&2
exit 1
