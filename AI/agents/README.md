# AI/agents — shared agent instruction modules

Canonical, reusable instruction modules for AI coding agents. Each module is a
self-contained Markdown file that a repo adopts by **vendoring a copy** into its
own `.agents/`.

## Why vendored copies, not symlinks

The consuming repos are used by more than one developer. A committed symlink to
`~/code/dotconfig/...` is **broken for anyone who does not have this private repo
cloned**, so shared modules are copied into the consuming repo as real files and
committed there — a plain `git clone` then works for everyone.

The cost is drift. The rule:

- **Edit the canonical module here, then re-vendor.**
- **Never edit a vendored copy in place.** Each one carries a provenance header
  saying so.

## Layout & current modules

| Module | What it covers | Vendored into |
| --- | --- | --- |
| `workflow.md` | End-to-end lifecycle **plan → implement → review → PR**, its gates, and the mandatory closing phases | `serenity_api` (`.agents/WORKFLOW.md`) |
| `tickets.md` | Plan/design docs → GitHub Issues; `gh-plan` lifecycle (`new`/`branch`/`pr`) | `serenity_api` (`.agents/TICKETS.md`), `serenity_ui` |
| `branching.md` | Feature-branch naming, `alpha` base + sync rules, how PRs link to issues | `serenity_api` (`.agents/BRANCHING.md`) |
| `tdd.md` | Test-Driven Development: failing test → hand to user → implement; the user owns all commits | `serenity_api` (`.agents/TDD.md`) |
| `PLAN_TEMPLATE.md` | The required plan skeleton: TDD-first phase plus the mandatory closing phases | `serenity_api` (`.agents/PLAN_TEMPLATE.md`) |
| `agent-rules.md` | Cross-cutting agent behaviour (phases, no commits, verification, tickets, gates) | (canonical reference) |

Repo-specific rules (commands, Definition of Done, stack guidance) are **not**
shared — they live in each repo's own `AGENTS.md` and `.agents/` files.

## How to vendor a module into a repo

Keep the repo's own `AGENTS.md` as the entry point and copy the module in — no
header and no attribution, so the copy is byte-identical to the canonical file:

```bash
cp ~/code/dotconfig/AI/agents/workflow.md <repo>/.agents/WORKFLOW.md
diff <repo>/.agents/WORKFLOW.md ~/code/dotconfig/AI/agents/workflow.md   # drift check
```

Then list it in the repo's `AGENTS.md` "Documentation map" so agents know to read
it before the relevant task.

> The planned `agent-toolkit` repo will provide `agents sync` / `agents check` to
> automate vendoring and detect drift; until then this is a manual copy.

## Prerequisites

These modules assume the GitHub CLI is installed and authenticated, and that a
`gh-plan` binary is available. Canonical source: `AI/bin/gh-plan`. It is being
vendored into each consuming repo so teammates do not need this repo checked out
(see `tickets.md`).
