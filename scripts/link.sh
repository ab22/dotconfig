#!/usr/bin/env bash
#
# Create the symlinks that make this machine use the dotconfig sources:
#   1. every file under root/<platform>/ mirrored into $HOME
#   2. the Neovim app configs (default `nvim` + the opt-in `nvim-nvchad` trial)
#   3. the generated editor configs under zed/ (run `task gen` first), then the
#      app configs: terminals, the Arch tiling desktop, VS Code
#   4. the global AI agent files (instructions + skills)
#
# Idempotent. It re-points existing links but never clobbers a real file or
# directory: anything that is not already a link is skipped with a warning so
# you can decide what to do with it.
#
# Usage: scripts/link.sh [macos|archlinux|linux|windows]   (default: auto-detect)
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
# A hardlink breaks as soon as git (or an editor) replaces the repo file instead
# of editing it in place, and the stale copy then looks like a real file. So each
# hardlink is recorded in $home/.local/state/dotconfig/hardlinks, and a recorded
# path that has drifted is re-linked on the next run — its old contents are kept
# as <file>.dotconfig-bak first, in case they held an edit.
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
  macos|archlinux|linux)
    if [ -z "$home" ]; then
      echo "link: ERROR HOME is not set" >&2
      exit 1
    fi
    nvim_dir="$home/.config/nvim"
    nvim_nvchad_dir="$home/.config/nvim-nvchad"
    zed_dir="$home/.config/zed"
    ;;
  *)
    echo "link: unknown platform '$platform' (expected macos, archlinux, linux or windows)" >&2
    exit 1
    ;;
esac

linked=0
unchanged=0
skipped=0
pruned=0

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

# The hardlinks this script made (see the header). Only ever written on a
# Windows shell with no symlink privilege; elsewhere it stays absent.
hardlink_manifest="$home/.local/state/dotconfig/hardlinks"

is_recorded_hardlink() { # is_recorded_hardlink <target>
  [ -f "$hardlink_manifest" ] && grep -qxF -- "$1" "$hardlink_manifest"
}

record_hardlink() { # record_hardlink <target>
  is_recorded_hardlink "$1" && return 0
  mkdir -p "$(dirname "$hardlink_manifest")"
  printf '%s\n' "$1" >> "$hardlink_manifest"
}

forget_hardlink() { # forget_hardlink <target>
  is_recorded_hardlink "$1" || return 0
  local rest
  rest="$(grep -vxF -- "$1" "$hardlink_manifest" || true)"
  if [ -n "$rest" ]; then
    printf '%s\n' "$rest" > "$hardlink_manifest"
  else
    rm -f -- "$hardlink_manifest"
  fi
}

create_link() { # create_link <source> <target>
  local src="$1" dst="$2"
  if $use_symlinks; then
    MSYS=winsymlinks:nativestrict ln -s "$src" "$dst" && forget_hardlink "$dst"
  elif [ -d "$src" ]; then
    # Junctions need no privilege. PowerShell rather than `mklink`, because
    # cmd.exe mangles the quoting of paths MSYS has converted.
    powershell -NoProfile -NonInteractive -Command \
      "New-Item -ItemType Junction -ErrorAction Stop -Path '$(win_native_path "$dst")' -Target '$(win_native_path "$src")' | Out-Null"
  else
    # hardlink: no -s, so Windows gets a second directory entry
    ln "$src" "$dst" && record_hardlink "$dst"
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
  elif [ -f "$dst" ] && [ ! -d "$src" ] && is_recorded_hardlink "$dst"; then
    # A hardlink this script made, orphaned when the repo file was replaced.
    # It is ours to re-link; keep its contents only if they differ.
    if cmp -s -- "$src" "$dst"; then
      rm -f -- "$dst"
    else
      mv -f -- "$dst" "$dst.dotconfig-bak"
      echo "link: note  $dst had drifted from the repo; old contents kept as $dst.dotconfig-bak"
    fi
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
#    The generic `linux` platform has no tree unless someone adds root/linux/;
#    it still gets everything below.
# ---------------------------------------------------------------------------
root_dir="$repo/root/$platform"
if [ -d "$root_dir" ]; then
  while IFS= read -r -d '' src; do
    link "$src" "$home/${src#"$root_dir"/}"
  done < <(find "$root_dir" -type f -print0)
elif [ "$platform" = linux ]; then
  echo "link: note  no root/linux/ tree — shell profiles left alone; put ~/.local/bin and ~/.cargo/bin on PATH yourself"
else
  echo "link: ERROR no config tree for '$platform' at $root_dir" >&2
  exit 1
fi

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
# 3b. App configs. Terminals on every unix (none of them ships the same config
#     path on Windows), the tiling desktop on Arch only — a generic `linux` box
#     is a dev machine or WSL, not that desktop — and VS Code everywhere, at
#     each platform's own user-settings path.
# ---------------------------------------------------------------------------
case "$platform" in
  macos|archlinux|linux)
    # Alacritty's config differs per OS; the themes it imports are shared.
    case "$platform" in
      macos) alacritty_variant=macos ;;
      *)     alacritty_variant=linux ;;
    esac
    link "$repo/alacritty/alacritty.$alacritty_variant.toml" "$home/.config/alacritty/alacritty.toml"
    link "$repo/alacritty/themes" "$home/.config/alacritty/themes"
    link "$repo/ghostty" "$home/.config/ghostty"
    link "$repo/kitty"   "$home/.config/kitty"
    ;;
esac

if [ "$platform" = archlinux ]; then
  for app in i3 i3status i3status-rs sway swaylock rofi; do
    link "$repo/$app" "$home/.config/$app"
  done
fi

case "$platform" in
  windows) vscode_dir="$roaming_appdata/Code/User" ;;
  macos)   vscode_dir="$home/Library/Application Support/Code/User" ;;
  *)       vscode_dir="$home/.config/Code/User" ;;
esac
link "$repo/vscode/settings.json" "$vscode_dir/settings.json"

# ---------------------------------------------------------------------------
# 4. Global AI agent files — one canonical source, each tool's expected path.
# ---------------------------------------------------------------------------
link "$repo/AI/AGENTS.md" "$home/AGENTS.md"          # generic AGENTS.md convention
link "$repo/AI/AGENTS.md" "$home/.dsh/AGENTS.md"     # DeepSeek Harness (user-global)
link "$repo/AI/AGENTS.md" "$home/.claude/CLAUDE.md"  # Claude Code (user memory)
# Skills: ONE LINK PER SKILL into each skill root — ~/.agents/skills (DSH, Codex)
# and ~/.claude/skills (Claude Code) — never the whole directory. Both roots must
# stay real directories: the `skills` CLI (`task skills`), Claude Code's plugin
# installers and `npx impeccable install` write skill folders into them, and a
# directory link would make those writes land inside this public repo.
# An older version of this script linked ~/.agents/skills wholesale; turn that
# link back into a directory (removing a link never touches what it points at).
if [ -L "$home/.agents/skills" ] && [ "$home/.agents/skills" -ef "$repo/AI/skills" ]; then
  rm -f -- "$home/.agents/skills"
  echo "link: note  ~/.agents/skills was a link to the whole repo directory — now one link per skill"
fi
for skill_root in "$home/.agents/skills" "$home/.claude/skills"; do
  for skill_dir in "$repo"/AI/skills/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    case "$skill_name" in
      .*) continue ;;   # a dot-directory is not a skill
    esac
    link "$skill_dir" "$skill_root/$skill_name"
  done
  # A skill deleted or renamed in the repo leaves its old link dangling. Prune
  # only links that point into this repo's AI/skills — everything else in the
  # directory belongs to the tool that installed it.
  for entry in "$skill_root"/*; do
    [ -L "$entry" ] && [ ! -e "$entry" ] || continue
    case "$(readlink "$entry")" in
      "$repo"/AI/skills/*)
        rm -f -- "$entry"
        echo "link: pruned $entry (skill no longer in the repo)"
        pruned=$((pruned + 1))
        ;;
    esac
  done
done
# Third-party skills are not linked: `task skills` installs them from
# AI/third-party-skills.txt with their own CLI.
# The rule files every AGENTS.md router points at: `~/.agents/rules/rust/RUST.md`,
# `~/.agents/rules/gates/TDD.md`, … A plain directory link, not a skill root —
# DSH never scans it, and nothing in it is model-invocable.
link "$repo/AI/rules"     "$home/.agents/rules"      # rule files (~/.agents/rules)
# Machine-specific environment facts (see AI/host-context.md). Loaded by DSH
# through the `~/AGENTS.md` pointer plus the `agent-instructions` entry in
# `~/.dsh/profiles/<p>/cordis.patch.yml`; keep that entry's candidate list in
# step with what AI/AGENTS.md documents.
link "$repo/AI/host-context.md" "$home/HOST.md"

# ---------------------------------------------------------------------------
# 4b. Global git ignore — one file that applies to EVERY repo on this machine.
#     It is what keeps `<repo>/.agents/local.md` (the per-repo agent overlay)
#     out of shared repositories; see AI/rules/README.md. Git reads the path
#     from core.excludesFile, so this link alone is not enough.
# ---------------------------------------------------------------------------
link "$repo/root/.gitignore" "$home/.gitignore"
# Set it only when unset or already ours — a different excludesFile is someone's
# deliberate choice, and overwriting it would silently drop their ignore rules.
excludes="$(git config --global --get core.excludesFile || true)"
case "$excludes" in
  "" | "~/.gitignore" | "$home/.gitignore")
    git config --global core.excludesFile "~/.gitignore"
    echo "link: ok    git core.excludesFile = ~/.gitignore"
    ;;
  *)
    echo "link: SKIP  git core.excludesFile is already '$excludes' — set it to ~/.gitignore to use the global ignore"
    skipped=$((skipped + 1))
    ;;
esac

# ---------------------------------------------------------------------------
# 5. agent-toolkit — installed as regular user binaries into ~/.local/bin by the
#    toolkit's own installer, which root/<os>/.zshrc puts on $PATH (and
#    root/windows/.bashrc on Windows).
# ---------------------------------------------------------------------------
toolkit="$home/code/agent-toolkit"
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
echo "link: done — $linked linked, $unchanged already linked, $skipped skipped, $pruned pruned"
if $windows && ! $use_symlinks; then
  echo "link: note — no symlink privilege here, so directories were linked with junctions and"
  echo "link:        files with hardlinks. A new login after enabling Developer Mode (Settings >"
  echo "link:        System > For developers) lets the next run replace them with symlinks."
fi
