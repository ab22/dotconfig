#!/usr/bin/env bash
#
# Print the dotconfig platform id for this machine: macos | archlinux | windows
#
# The id names the matching directory under root/ (root/<id>/) and is what
# scripts/gen.sh and scripts/link.sh default to when no argument is given.
#
# `windows` means Git for Windows (git-bash/MSYS), which is the shell the
# Windows scripts run under. WSL reports Linux, so a WSL machine is treated as
# a Linux one and needs an Arch-based distribution there.
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
    if [ -r /etc/os-release ] && grep -qiE '^(ID|ID_LIKE)=.*arch' /etc/os-release; then
      echo archlinux
      exit 0
    fi
    echo "detect-os: unsupported Linux distribution — expected an Arch-based system" >&2
    exit 1
    ;;
esac

echo "detect-os: unsupported operating system: $(uname -s)" >&2
exit 1
