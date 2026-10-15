#!/usr/bin/env bash
#
# Install the third-party skills listed in AI/third-party-skills.txt, globally,
# with the `skills` CLI (npx skills add):
#   -a codex        → ~/.agents/skills   (also the skill root DSH reads)
#   -a claude-code  → ~/.claude/skills
# First-party skills are not handled here: link.sh links AI/skills/* into both
# roots. Run link.sh first — it turns a legacy ~/.agents/skills directory link
# into a real directory, so these installs never land inside the repo.
#
# Usage: scripts/skills.sh [--update]
#   (none)    install each listed skill that is missing from either root.
#             Idempotent, and needs no network once everything is present.
#   --update  re-install every listed skill from its source (latest upstream).
#
# A machine without Node.js still finishes `task install`: this reports the gap
# and exits 0. A skill that fails to install is reported and exits 1.
#
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
manifest="$repo/AI/third-party-skills.txt"
# Pinned: its flags are the interface this script relies on. Bump deliberately.
skills_cli="skills@1.7.2"

update=false
case "${1:-}" in
  "") ;;
  --update) update=true ;;
  *)
    echo "skills: usage: scripts/skills.sh [--update]" >&2
    exit 2
    ;;
esac

# The CLI is Node, and Node's home on Windows is %USERPROFILE% whatever $HOME
# says (they differ under MSYS2), so look where it will write.
case "$(uname -s)" in
  MINGW* | MSYS* | CYGWIN*) home="$(cygpath -u "${USERPROFILE:?USERPROFILE is not set}")" ;;
  *) home="${HOME:?HOME is not set}" ;;
esac
if [ "$(cd "$home/.agents/skills" 2>/dev/null && pwd -P)" = "$repo/AI/skills" ]; then
  echo "skills: ERROR ~/.agents/skills still links into the repo — run 'task link' first" >&2
  exit 1
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "skills: note  npx not found — third-party skills skipped; install Node.js, then run 'task skills'"
  exit 0
fi

# The CLI links each agent's copy to one canonical copy. Without symlink
# privilege on Windows (no Developer Mode) that would fail, so copy there.
copy_flag=""
case "$(uname -s)" in
  MINGW* | MSYS* | CYGWIN*)
    probe="$(mktemp -d)"
    : > "$probe/target"
    if ! { MSYS=winsymlinks:nativestrict ln -s "$probe/target" "$probe/link" 2>/dev/null && [ -L "$probe/link" ]; }; then
      copy_flag="--copy"
    fi
    rm -rf "$probe"
    ;;
esac

installed=0
present=0
failed=0
log="$(mktemp)"
while read -r source skill rest <&3; do
  case "$source" in "" | "#"*) continue ;; esac
  if [ -z "$skill" ] || [ -n "$rest" ]; then
    echo "skills: ERROR malformed line in $manifest: $source $skill $rest" >&2
    failed=$((failed + 1))
    continue
  fi
  if ! $update && [ -f "$home/.agents/skills/$skill/SKILL.md" ] && [ -f "$home/.claude/skills/$skill/SKILL.md" ]; then
    echo "skills: ok    $skill (already installed)"
    present=$((present + 1))
    continue
  fi
  # stdin from /dev/null: the CLI must never wait on a prompt inside `task`.
  if DISABLE_TELEMETRY=1 npx -y "$skills_cli" add "$source" --skill "$skill" \
      -g -a codex -a claude-code -y $copy_flag < /dev/null > "$log" 2>&1 &&
    [ -f "$home/.agents/skills/$skill/SKILL.md" ] && [ -f "$home/.claude/skills/$skill/SKILL.md" ]; then
    echo "skills: ok    $skill <- $source"
    installed=$((installed + 1))
  else
    echo "skills: ERROR could not install $skill from $source:" >&2
    tail -n 15 "$log" | sed 's/^/skills:   /' >&2
    failed=$((failed + 1))
  fi
done 3< "$manifest"
rm -f "$log"

echo "skills: done — $installed installed, $present already installed, $failed failed"
[ "$failed" -eq 0 ]
