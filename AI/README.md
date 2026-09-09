# AI (shared agent tooling)

Shared, repo-agnostic tooling for AI coding agents working across projects.
Scripts here are exposed on `$PATH` (see `root/<os>/.zshrc`), so agents can run
them from any repo without a `./scripts/...` path.

## Layout

| Path | Purpose |
| --- | --- |
| `bin/` | Executable scripts on `$PATH`. |
| `agents/` | shared agent-instruction modules that project `AGENTS.md` /
`.agents/` files can reference. |

## Current tools

### `gh-plan` — file plan docs as GitHub Issues

Turns a plan/wireframe doc into ticket(s) on `ab22/serenity_api` / `ab22/serenity_ui`
(title + summary + the full doc embedded in the body, `plan` label, companion
cross-links when it files both, then deletes the local doc). Also derives the
implementation branch name (`feat/api-<n>-<slug>` / `feat/ui-<n>-<slug>`).

```bash
gh-plan new <doc> [--repo api|ui|both] [--title ...] [--summary ...] [--keep] [--dry-run]
gh-plan branch <api|ui> <issue-id> [--create]
```

Workflow + conventions live in each project's `.agents/TICKETS.md`
(`serenity_api`, `serenity_ui`). Requires the `gh` CLI (authed).

## Install

Ensure this repo is cloned at `~/code/dotconfig` and the `.zshrc` exports
`$HOME/code/dotconfig/AI/bin` on `$PATH`; then open a new shell.
