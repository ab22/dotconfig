#!/usr/bin/env bash
#
# Re-sync the vendored NvChad starter in nvim-nvchad/ with its upstream repo,
# preserving local edits.
#
# nvim-nvchad/UPSTREAM records the upstream url, ref, and the commit we last
# vendored. For every file upstream ships:
#   * local == previously vendored version -> replace with the new version
#   * local differs (you edited it)        -> keep local, leave the new version
#                                             beside it as <file>.upstream
#   * file is new upstream                 -> add it
# Files upstream deleted are removed only when you have not modified them.
# README.md is owned by this repo and never synced.
#
# The recorded commit advances after a successful run, so each upstream change
# is merged at most once. Exit code 1 means at least one conflict needs review.
#
# Usage: scripts/update-nvchad.sh [--dry-run]
#
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target="$repo/nvim-nvchad"
upstream_file="$target/UPSTREAM"

# Files owned by this repo; never overwritten or removed by an update.
keep_local="README.md"

dry_run=false
case "${1:-}" in
  --dry-run) dry_run=true ;;
  "") ;;
  *) echo "update-nvchad: usage: ${0##*/} [--dry-run]" >&2; exit 2 ;;
esac

[ -f "$upstream_file" ] || {
  echo "update-nvchad: ERROR missing $upstream_file" >&2
  exit 1
}

read_field() { # read_field <key>
  sed -n "s/^$1=//p" "$upstream_file" | head -n1
}

update_field() { # update_field <key> <value>
  local tmpf
  tmpf="$(mktemp)"
  sed "s|^$1=.*|$1=$2|" "$upstream_file" > "$tmpf"
  mv "$tmpf" "$upstream_file"
}

is_kept() { # is_kept <relative-path>
  local rel="$1" k
  for k in $keep_local; do
    [ "$rel" = "$k" ] && return 0
  done
  return 1
}

find_upstream_conflicts() { # leftover <file>.upstream artifacts
  find "$target" -name '*.upstream' -type f 2>/dev/null | sed "s|^$repo/||"
}

url="$(read_field url)"
ref="$(read_field ref)"
old_commit="$(read_field commit)"
if [ -z "$url" ] || [ -z "$ref" ] || [ -z "$old_commit" ]; then
  echo "update-nvchad: ERROR $upstream_file must define url=, ref= and commit=" >&2
  exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "update-nvchad: fetching $url ($ref)"
git clone --quiet "$url" "$tmp/upstream"
git -C "$tmp/upstream" fetch --quiet origin "$ref"
new_commit="$(git -C "$tmp/upstream" rev-parse "origin/$ref")"

if [ "$new_commit" = "$old_commit" ]; then
  echo "update-nvchad: already up to date at $new_commit"
  leftovers="$(find_upstream_conflicts)"
  if [ -n "$leftovers" ]; then
    echo "update-nvchad: NOTE unresolved conflict artifacts still present:" >&2
    echo "$leftovers" | sed 's/^/  /' >&2
  fi
  exit 0
fi
echo "update-nvchad: vendored $old_commit -> upstream $new_commit"

mkdir -p "$tmp/old" "$tmp/new"
git -C "$tmp/upstream" ls-tree -r --name-only "$old_commit" | sort > "$tmp/old.list"
git -C "$tmp/upstream" ls-tree -r --name-only "$new_commit" | sort > "$tmp/new.list"
git -C "$tmp/upstream" archive "$old_commit" | tar -x -C "$tmp/old"
git -C "$tmp/upstream" archive "$new_commit" | tar -x -C "$tmp/new"

added=0
updated=0
removed=0
kept=0
conflicts=0

copy_in() { # copy_in <relative-path>
  local rel="$1"
  if $dry_run; then
    return 0
  fi
  mkdir -p "$target/$(dirname "$rel")"
  cp "$tmp/new/$rel" "$target/$rel"
}

# --- files upstream ships ---
while IFS= read -r rel; do
  is_kept "$rel" && continue

  if [ ! -e "$target/$rel" ]; then
    if [ -e "$tmp/old/$rel" ]; then
      echo "update-nvchad: KEPT    $rel (deleted locally)"
      kept=$((kept + 1))
    else
      echo "update-nvchad: ADDED   $rel"
      copy_in "$rel"
      added=$((added + 1))
    fi
    continue
  fi

  # Already identical to the new version (including a resolved conflict).
  cmp -s "$target/$rel" "$tmp/new/$rel" && continue

  if [ -e "$tmp/old/$rel" ] && cmp -s "$target/$rel" "$tmp/old/$rel"; then
    echo "update-nvchad: UPDATED $rel"
    copy_in "$rel"
    updated=$((updated + 1))
  else
    echo "update-nvchad: CONFLICT $rel (kept local; new version at $rel.upstream)"
    if ! $dry_run; then
      cp "$tmp/new/$rel" "$target/$rel.upstream"
    fi
    conflicts=$((conflicts + 1))
  fi
done < "$tmp/new.list"

# --- files upstream removed ---
while IFS= read -r rel; do
  is_kept "$rel" && continue
  [ -e "$tmp/new/$rel" ] && continue
  [ -e "$target/$rel" ] || continue

  if cmp -s "$target/$rel" "$tmp/old/$rel"; then
    echo "update-nvchad: REMOVED $rel (deleted upstream)"
    if ! $dry_run; then
      rm -f "$target/$rel"
    fi
    removed=$((removed + 1))
  else
    echo "update-nvchad: CONFLICT $rel (deleted upstream, modified locally — kept)"
    conflicts=$((conflicts + 1))
  fi
done < "$tmp/old.list"

echo
summary="$added added, $updated updated, $removed removed, $kept kept, $conflicts conflict(s)"

if $dry_run; then
  echo "update-nvchad: dry run — $summary — nothing written"
  exit 0
fi

# Advance the recorded commit even when conflicts happened: the applied changes
# are real, and the .upstream artifacts mark what still needs review.
update_field commit "$new_commit"
update_field vendored "$(date -u +%F)"

echo "update-nvchad: $summary"
echo "update-nvchad: recorded $new_commit in nvim-nvchad/UPSTREAM"

if [ "$conflicts" -gt 0 ]; then
  echo "update-nvchad: review the .upstream files, fold in what you want, then delete them." >&2
  exit 1
fi
