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
| `AI/skills/` | **first-party capabilities** the model invokes (not rules) — linked per skill into `~/.agents/skills` and `~/.claude/skills` |
| `AI/third-party-skills.txt` | third-party skills by source — installed by `task skills`, never vendored |
| `AI/host-context.md` | this machine's facts — symlinked to `~/HOST.md` |
| `root/<os>/` | per-OS shell profiles and `$HOME` files, mirrored into `$HOME` |
| `root/.gitignore` | the **global** git ignore — symlinked to `~/.gitignore` |
| `scripts/` | `gen.sh`, `link.sh`, `detect-os.sh`, `update-nvchad.sh` |
| `nvim/`, `nvim-nvchad/`, `zed/`, `vscode/` | editor configs, linked on every platform |
| `alacritty/`, `ghostty/`, `kitty/` | terminal configs, linked on macOS and Linux |
| `i3*/`, `sway*/`, `rofi/` | the tiling desktop, linked on Arch only |

## Commands

The scripts are bash. On Windows the Taskfile runs them with Git-for-Windows bash
by absolute path (`C:\Program Files\Git\bin\bash.exe` — `Git\cmd` is on `PATH`
but holds no `bash.exe`, and a bare `bash` may be WSL's), so `task` works from
git-bash, cmd.exe, or PowerShell as `task.cmd`.

```bash
task gen        # generate OS-specific artifacts (auto-detects macos/archlinux/linux/windows)
task link       # symlink dotfiles, app configs, global agent files, ~/.gitignore
task skills     # install the third-party skills in AI/third-party-skills.txt (Node.js)
task install    # gen + link + skills
```

`link.sh` is idempotent, never clobbers a real file, re-points stale links, and
prunes per-skill links (in `~/.agents/skills` and `~/.claude/skills`) whose skill
left the repo. It reports
`linked` / `already linked` / `skipped` / `pruned` counts — **check the count**: a
`SKIP` means a real file is shadowing the repo's version. A second `task install`
must report `0 linked`; anything else is an idempotency bug.

## Rules that have already cost time here

- **Link, never copy.** A copied file drifts and the next `task link` cannot tell
  it apart from a real one. Every file under `root/<os>/` and every app config is
  a symlink (junction or hardlink on a Windows shell with no symlink privilege).
- **Adding a symlink target means editing `scripts/link.sh`.** It enumerates what
  it links; a new directory under the repo root is invisible until it is added.
- **A new global ignore rule goes in `root/.gitignore`**, never in a repo's own
  `.gitignore` and never in `~/.gitconfig`. `git check-ignore -v <path>` names the
  rule responsible.
- **A new rule is a rule file under `AI/rules/`, named by a router row in
  `AI/AGENTS.md` or in its language file** — read `AI/rules/README.md` and use the
  `authoring-agent-files` skill. A rule file that nothing routes to does not load,
  so the router row is part of the change.
- **A rule is not a skill.** `AI/skills/` holds capabilities the model invokes;
  every skill's catalogue entry costs tokens in every session. Rules are plain
  files, read on demand, and cost nothing until read. Do not put a rule in
  `AI/skills/`.
- **This repo is public.** No private project names, paths, ports, hostnames or
  credentials in any committed file — the global ignore list exists because the
  machine-local context is exactly the part that must not be published.
