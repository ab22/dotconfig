# AI/agents — shared agent instruction modules

Canonical, reusable instruction modules for AI coding agents. Each module is a
self-contained Markdown file that a repo can adopt by **symlinking** it into its
own `.agents/` (or by copying when the repo must stay self-contained).

## Layout & current modules

| Module | What it covers | Adopted by |
| --- | --- | --- |
| `tickets.md` | Plan/design docs → GitHub Issues; `gh-plan` lifecycle (`new`/`branch`/`pr`) | `serenity_api`, `serenity_ui` (as `.agents/TICKETS.md`) |
| `branching.md` | Feature-branch naming + how PRs link to issues | (canonical reference) |
| `tdd.md` | Test-Driven Development discipline | (canonical reference) |
| `agent-rules.md` | Cross-cutting agent behaviour (phases, no commits, verification, tickets) | (canonical reference) |

## How to adopt a module in a repo

Repos keep their own `AGENTS.md` as the entry point. For a shared module, prefer
a **relative symlink** from the repo's `.agents/` to the canonical file, so there
is a single source of truth (no drift):

```bash
# from <repo>/.agents/, repos are siblings under ~/code with dotconfig beside them
ln -s ../../dotconfig/AI/agents/tickets.md TICKETS.md
```

Relative targets work as long as the repos live next to `dotconfig` (this
workspace layout: `~/code/serenity_api`, `~/code/serenity_ui`,
`~/code/dotconfig`). If that layout cannot be assumed, copy the module instead
and re-sync on change.

Then list the file in the repo's `AGENTS.md` "Documentation map" so agents know
to read it before the relevant task.

## Prerequisites

These modules assume the GitHub CLI is installed and authenticated, and that the
`gh-plan` tool is on `$PATH` (see `AI/bin/gh-plan` + `AI/README.md`).
