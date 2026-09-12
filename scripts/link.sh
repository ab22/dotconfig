#!/usr/bin/env bash
#
# Create the symlinks that make this machine use the dotconfig sources:
#   1. every file under root/<platform>/ mirrored into $HOME
#   2. the generated editor configs under zed/ (run `task gen` first)
#   3. the global AI agent files (instructions + skills)
#
# Idempotent. It re-points existing symlinks but never clobbers a real file or
# directory: anything that is not already a symlink is skipped with a warning so
# you can decide what to do with it.
#
# Usage: scripts/link.sh [macos|archlinux]     (default: auto-detect)
#
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
platform="${1:-$("$repo/scripts/detect-os.sh")}"
home="${HOME:?HOME is not set}"

linked=0
skipped=0

link() { # link <source> <target>
  local src="$1" dst="$2"
  if [ ! -e "$src" ]; then
    echo "link: ERROR missing source: $src" >&2
    exit 1
  fi
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    ln -sfn "$src" "$dst"
  elif [ -e "$dst" ]; then
    echo "link: SKIP  $dst (exists and is not a symlink — move it aside to adopt)"
    skipped=$((skipped + 1))
    return 0
  else
    ln -s "$src" "$dst"
  fi
  echo "link: ok    $dst -> $src"
  linked=$((linked + 1))
}

# ---------------------------------------------------------------------------
# 1. Home dotfiles — mirror every file under root/<platform>/ into $HOME.
#    Recursing to files (rather than linking directories wholesale) keeps
#    $HOME/.local and friends safe to share with unrelated tooling.
# ---------------------------------------------------------------------------
root_dir="$repo/root/$platform"
if [ ! -d "$root_dir" ]; then
  echo "link: ERROR no config tree for '$platform' at $root_dir" >&2
  exit 1
fi
while IFS= read -r -d '' src; do
  link "$src" "$home/${src#"$root_dir"/}"
done < <(find "$root_dir" -type f -print0)

# ---------------------------------------------------------------------------
# 2. Generated editor configs — `task gen` owns these files.
# ---------------------------------------------------------------------------
for f in settings.json keymap.json tasks.json; do
  if [ ! -e "$repo/zed/$f" ]; then
    echo "link: ERROR $repo/zed/$f is missing — run 'task gen' first" >&2
    exit 1
  fi
  link "$repo/zed/$f" "$home/.config/zed/$f"
done

# ---------------------------------------------------------------------------
# 3. Global AI agent files — one canonical source, each tool's expected path.
# ---------------------------------------------------------------------------
link "$repo/AI/AGENTS.md" "$home/AGENTS.md"          # generic AGENTS.md convention
link "$repo/AI/AGENTS.md" "$home/.dsh/AGENTS.md"     # DeepSeek Harness (user-global)
link "$repo/AI/AGENTS.md" "$home/.claude/CLAUDE.md"  # Claude Code (user memory)
link "$repo/AI/skills"    "$home/.agents/skills"     # DSH skill root (~/.agents/skills)

# ---------------------------------------------------------------------------
# 4. agent-toolkit — installed as regular user binaries into ~/.local/bin by the
#    toolkit's own installer, which root/<os>/.zshrc puts on $PATH.
# ---------------------------------------------------------------------------
toolkit="$HOME/code/agent-toolkit"
if [ -x "$toolkit/scripts/install.sh" ]; then
  bash "$toolkit/scripts/install.sh" | sed 's/^/  /'
else
  echo "link: note — $toolkit not found; skipping the agent-toolkit install"
fi

echo
echo "link: done — $linked linked, $skipped skipped"
