#!/usr/bin/env bash
#
# Create the symlinks that make this machine use the dotconfig sources:
#   1. every file under root/<platform>/ mirrored into $HOME
#   2. the Neovim app configs (default `nvim` + the opt-in `nvim-nvchad` trial)
#   3. the generated editor configs under zed/ (run `task gen` first)
#   4. the global AI agent files (instructions + skills)
#
# Idempotent. It re-points existing links but never clobbers a real file or
# directory: anything that is not already a link is skipped with a warning so
# you can decide what to do with it.
#
# Usage: scripts/link.sh [macos|archlinux|windows]   (default: auto-detect)
#
# Windows (git-bash): MSYS `ln -s` silently *copies* unless Windows grants the
# "create symbolic links" right, which a normal user only has in Developer Mode
# (Settings > System > For developers) or from an elevated shell. So this script
# asks for that right first, and otherwise links with whatever keeps repo and
# target the same file instead of a drifting copy:
#   * symlink   — Developer Mode on or elevated shell (probed, preferred)
#   * junction  — fallback for directories (a real reparse point, no privilege)
#   * hardlink  — fallback for files (same contents, second directory entry)
#
set -euo pipefail

# `pwd -P` because on Windows a shell launched by go-task can inherit a
# Windows-form PWD, which would otherwise turn $repo into a C:/... path here.
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
platform="${1:-$("$repo/scripts/detect-os.sh")}"

win_path() { # win_path <path> — a Windows path in the /c/... form MSYS uses
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -u "$1"
  else
    printf '%s\n' "$1"
  fi
}

win_native_path() { # win_native_path <path> — the C:\... form cmd/PowerShell want
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -w "$1"
  else
    printf '%s\n' "$1"
  fi
}

windows=false
if [ "$platform" = windows ]; then
  windows=true
fi

# Where each app reads its config from. Neovim and Zed do not use $HOME/.config
# on Windows: Neovim's stdpath('config') is %LOCALAPPDATA%\nvim, and Zed's
# config directory is %APPDATA%\Zed.
home="${HOME:-}"
case "$platform" in
  windows)
    if [ -z "$home" ]; then
      home="$(win_path "${USERPROFILE:?HOME and USERPROFILE are both unset}")"
    fi
    local_appdata="$(win_path "${LOCALAPPDATA:-$home/AppData/Local}")"
    roaming_appdata="$(win_path "${APPDATA:-$home/AppData/Roaming}")"
    nvim_dir="$local_appdata/nvim"
    nvim_nvchad_dir="$local_appdata/nvim-nvchad"
    zed_dir="$roaming_appdata/Zed"
    ;;
  *)
    if [ -z "$home" ]; then
      echo "link: ERROR HOME is not set" >&2
      exit 1
    fi
    nvim_dir="$home/.config/nvim"
    nvim_nvchad_dir="$home/.config/nvim-nvchad"
    zed_dir="$home/.config/zed"
    ;;
esac

linked=0
unchanged=0
skipped=0

# ---------------------------------------------------------------------------
# Link creation. On Windows a symlink needs the privilege described above; the
# fallbacks differ from unix (junction/hardlink), and plain `ln -s` is never
# used there because it would copy.
# ---------------------------------------------------------------------------
use_symlinks=true
if $windows; then
  # Probe once. MSYS reports the refusal instead of quietly copying when
  # winsymlinks is nativestrict, which is exactly the question being asked.
  use_symlinks=false
  probe_dir="$(mktemp -d)"
  : > "$probe_dir/target"
  if MSYS=winsymlinks:nativestrict ln -s "$probe_dir/target" "$probe_dir/link" 2>/dev/null &&
    [ -L "$probe_dir/link" ]; then
    use_symlinks=true
  fi
  rm -rf "$probe_dir"
fi

create_link() { # create_link <source> <target>
  local src="$1" dst="$2"
  if $use_symlinks; then
    MSYS=winsymlinks:nativestrict ln -s "$src" "$dst"
  elif [ -d "$src" ]; then
    # Junctions need no privilege. PowerShell rather than `mklink`, because
    # cmd.exe mangles the quoting of paths MSYS has converted.
    powershell -NoProfile -NonInteractive -Command \
      "New-Item -ItemType Junction -ErrorAction Stop -Path '$(win_native_path "$dst")' -Target '$(win_native_path "$src")' | Out-Null"
  else
    ln "$src" "$dst" # hardlink: no -s, so Windows gets a second directory entry
  fi
}

link() { # link <source> <target>
  local src="$1" dst="$2"
  if [ ! -e "$src" ]; then
    echo "link: ERROR missing source: $src" >&2
    exit 1
  fi
  mkdir -p "$(dirname "$dst")"

  # Already the same file (symlink, junction or hardlink)? Leave it alone —
  # recreating it would needlessly downgrade a symlink to a junction or hardlink
  # on a Windows shell with no symlink privilege. The one exception is a
  # hardlink on a shell that *can* make symlinks: promote it.
  if [ "$dst" -ef "$src" ]; then
    if [ -L "$dst" ] || ! $use_symlinks; then
      echo "link: ok    $dst -> $src (already linked)"
      unchanged=$((unchanged + 1))
      return 0
    fi
    rm -rf -- "$dst"
  elif [ -L "$dst" ]; then
    # A link, but stale or pointing elsewhere: drop it and re-point. Removing a
    # junction or hardlink only drops the extra directory entry — it never
    # touches the tree it points at.
    rm -rf -- "$dst"
  elif [ -e "$dst" ]; then
    echo "link: SKIP  $dst (exists and is not a symlink — move it aside to adopt)"
    skipped=$((skipped + 1))
    return 0
  fi

  if ! create_link "$src" "$dst"; then
    echo "link: ERROR could not link $dst -> $src" >&2
    if $windows; then
      echo "link:       symlinks need Developer Mode or an elevated shell; junctions and hardlinks need both paths on one volume" >&2
    fi
    exit 1
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
# 2. Neovim app configs — one directory per app name, so both coexist without
#    sharing plugin/data state. Plain `nvim` keeps the original config; the
#    NvChad trial runs under NVIM_APPNAME=nvim-nvchad (the `nvchad` alias).
# ---------------------------------------------------------------------------
link "$repo/nvim"        "$nvim_dir"
link "$repo/nvim-nvchad" "$nvim_nvchad_dir"

# ---------------------------------------------------------------------------
# 3. Generated editor configs — `task gen` owns these files.
# ---------------------------------------------------------------------------
for f in settings.json keymap.json tasks.json; do
  if [ ! -e "$repo/zed/$f" ]; then
    echo "link: ERROR $repo/zed/$f is missing — run 'task gen' first" >&2
    exit 1
  fi
  link "$repo/zed/$f" "$zed_dir/$f"
done

# ---------------------------------------------------------------------------
# 4. Global AI agent files — one canonical source, each tool's expected path.
# ---------------------------------------------------------------------------
link "$repo/AI/AGENTS.md" "$home/AGENTS.md"          # generic AGENTS.md convention
link "$repo/AI/AGENTS.md" "$home/.dsh/AGENTS.md"     # DeepSeek Harness (user-global)
link "$repo/AI/AGENTS.md" "$home/.claude/CLAUDE.md"  # Claude Code (user memory)
link "$repo/AI/skills"    "$home/.agents/skills"     # DSH skill root (~/.agents/skills)
# Machine-specific environment facts (see AI/host-context.md). Loaded by DSH via
# the `instructionFileCandidates` list in the profile patch, not by convention —
# so this link must exist wherever that candidate list is configured.
link "$repo/AI/host-context.md" "$home/HOST.md"

# ---------------------------------------------------------------------------
# 5. agent-toolkit — installed as regular user binaries into ~/.local/bin by the
#    toolkit's own installer, which root/<os>/.zshrc puts on $PATH (and
#    root/windows/.bashrc on Windows).
# ---------------------------------------------------------------------------
toolkit="$HOME/code/agent-toolkit"
if [ -x "$toolkit/scripts/install.sh" ]; then
  # The installer links with plain `ln -sfn`, which copies on Windows unless
  # MSYS is told to insist on real symlinks.
  if $windows && $use_symlinks; then
    MSYS=winsymlinks:nativestrict bash "$toolkit/scripts/install.sh" | sed 's/^/  /'
  else
    bash "$toolkit/scripts/install.sh" | sed 's/^/  /'
  fi
else
  echo "link: note — $toolkit not found; skipping the agent-toolkit install"
fi

echo
echo "link: done — $linked linked, $unchanged already linked, $skipped skipped"
if $windows && ! $use_symlinks; then
  echo "link: note — no symlink privilege here, so directories were linked with junctions and"
  echo "link:        files with hardlinks. A new login after enabling Developer Mode (Settings >"
  echo "link:        System > For developers) lets the next run replace them with symlinks."
fi
