#!/usr/bin/env bash
#
# Generate the OS-specific config artifacts by merging each *.base.json with the
# matching OS override file. One entry point for every platform.
#
# Usage: scripts/gen.sh [macos|archlinux]      (default: auto-detect)
#
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
platform="${1:-$("$repo/scripts/detect-os.sh")}"

case "$platform" in
  macos)     zed_os="mac" ;;
  archlinux) zed_os="linux" ;;
  *)
    echo "gen: unknown platform '$platform' (expected macos or archlinux)" >&2
    exit 1
    ;;
esac

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
