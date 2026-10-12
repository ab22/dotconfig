#!/usr/bin/env bash
#
# Generate the OS-specific config artifacts by merging each *.base.json with the
# matching OS override file. One entry point for every platform.
#
# Usage: scripts/gen.sh [macos|archlinux|windows]   (default: auto-detect)
#
set -euo pipefail

# `pwd -P` because on Windows a shell launched by go-task can inherit a
# Windows-form PWD, which would otherwise turn $repo into a C:/... path here.
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
platform="${1:-$("$repo/scripts/detect-os.sh")}"

case "$platform" in
  macos)     zed_os="mac" ;;
  archlinux) zed_os="linux" ;;
  windows)   zed_os="windows" ;;
  *)
    echo "gen: unknown platform '$platform' (expected macos, archlinux or windows)" >&2
    exit 1
    ;;
esac

# jq does the merging, and a jq that is installed but not on PATH is the usual
# Windows stumble — say so instead of failing on a bare "command not found".
if ! command -v jq >/dev/null 2>&1; then
  cat >&2 <<'EOF'
gen: ERROR jq is required but was not found on PATH
gen:   macOS       brew install jq
gen:   Arch Linux  sudo pacman -S jq
gen:   Windows     winget install jqlang.jq   (then restart your shell)
EOF
  exit 1
fi

merge() { # merge <base> <override> <output> <jq-operator>
  local base="$1" override="$2" out="$3" op="$4"
  if [ ! -f "$base" ] || [ ! -f "$override" ]; then
    echo "gen: missing input for $(basename "$out"): $base / $override" >&2
    exit 1
  fi
  jq -s ".[0] $op .[1]" "$base" "$override" > "$out"
  echo "gen: $out"
}

merge "$repo/zed/settings.base.json" "$repo/zed/settings.${zed_os}_overrides.json" "$repo/zed/settings.json" '*'
merge "$repo/zed/keymap.base.json"   "$repo/zed/keymap.${zed_os}_overrides.json"   "$repo/zed/keymap.json"   '+'
merge "$repo/zed/tasks.base.json"    "$repo/zed/tasks.${zed_os}_overrides.json"    "$repo/zed/tasks.json"    '+'
