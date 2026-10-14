---
workflow: personal
rules: []
---

# AGENTS.md — dotconfig

Personal dotfiles plus the **agent context system** for this machine. The canonical
layout is described in [`AI/rules/README.md`](AI/rules/README.md);
[`README.md`](README.md) is the human entry point for the dotfiles themselves.

`workflow: personal` means what it says: **no TDD gate, no tickets, no phase
planning, no dev/release branch flow.** The review gate
(`~/.agents/rules/gates/CODE_REVIEW.md`) still applies — a change to a shell script
or a symlink rule is worth a second look before it is committed, and a broken
`task install` costs more than the review. The machine-local overrides for this
checkout are in `.agents/local.md` (gitignored).

## What this repo is

| Path | Holds |
| --- | --- |
| `AI/AGENTS.md` | the machine-global agent baseline (**the router**) — symlinked to `~/AGENTS.md`, `~/.dsh/AGENTS.md`, `~/.claude/CLAUDE.md` |
| `AI/rules/README.md` | the **canonical** authoring manual — the router model, file kinds, switch grammar, where a rule belongs |
| `AI/rules/` | the rule files, read on demand — symlinked to `~/.agents/rules` |
| `AI/skills/` | **capabilities** the model invokes (not rules) — symlinked to `~/.agents/skills` |
| `AI/host-context.md` | this machine's facts — symlinked to `~/HOST.md` |
| `AI/agents/` | **retired** modules, kept for reference while repos migrate — not loaded |
| `root/<os>/` | per-OS shell profiles and `$HOME` files, mirrored into `$HOME` |
| `root/.gitignore` | the **global** git ignore — symlinked to `~/.gitignore` |
| `scripts/` | `gen.sh`, `link.sh`, `detect-os.sh`, `update-nvchad.sh` |
| `nvim/`, `nvim-nvchad/`, `zed/`, `alacritty/`, `ghostty/`, `kitty/`, `i3*/`, `rofi/`, `sway*`, `vscode/` | app configs, symlinked into place |

## Commands

The scripts are bash. On Windows they run under the Git-for-Windows bash, so run
`task` from a **git-bash** shell (`C:\Program Files\Git\cmd` is on `PATH` but
holds no `bash.exe`; the binary is at `C:\Program Files\Git\bin\bash.exe`).

```bash
task gen        # generate OS-specific artifacts (auto-detects macos/archlinux/windows)
task link       # symlink dotfiles, editor configs, global agent files, ~/.gitignore
task install    # gen + link
```

`link.sh` is idempotent, never clobbers a real file, and re-points stale links.
It reports `linked` / `already linked` / `SKIP` counts — **check the count**, a
silent `SKIP` means a real file is shadowing the repo's version.

## Rules that have already cost time here

- **Link, never copy.** A copied file drifts and the next `task link` cannot tell
  it apart from a real one. Every file under `root/<os>/` and every app config is
  a symlink (junction or hardlink on a Windows shell with no symlink privilege).
- **Adding a symlink target means editing `scripts/link.sh`.** It enumerates what
  it links; a new directory under the repo root is invisible until it is added.
- **A new global ignore rule goes in `root/.gitignore`**, never in a repo's own
  `.gitignore` and never in `~/.gitconfig`. `git check-ignore -v <path>` names the
  rule responsible.
- **`AI/agents/` is retired.** Do not add to it. **A new rule is a rule file under
  `AI/rules/`, named by a router row in `AI/AGENTS.md` or in its language file** —
  read `AI/rules/README.md` and use the `authoring-agent-files` skill. A rule file
  that nothing routes to does not load, so the router row is part of the change.
- **A rule is not a skill.** `AI/skills/` holds capabilities the model invokes;
  every skill's catalogue entry costs tokens in every session. Rules are plain
  files, read on demand, and cost nothing until read. Do not put a rule in
  `AI/skills/`.
- **This repo is public.** No private project names, paths, ports, hostnames or
  credentials in any committed file — the global ignore list exists because the
  machine-local context is exactly the part that must not be published.
