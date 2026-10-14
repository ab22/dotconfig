# AI/agents — retired modules

> **Retired. Do not add to this directory.** These are the pre-router instruction
> modules, kept as reference while repositories migrate. They are **not loaded** by
> anything: no symlink points at them, and no router row reaches them.
>
> New rules are **rule files** under `AI/rules/`. Read
> [`../rules/README.md`](../rules/README.md) — the canonical authoring manual — and
> use the `authoring-agent-files` skill.

## Why they were retired

They were vendored as byte-identical copies into consuming repos, which meant:

- **Every rule was always-on in the repos that had them, and invisible in the repos
  that did not.** `rust.md` carried general Rust *and* HTTP status-code mapping in
  one 10.5 KB file; a repo that needed one got both.
- **Shared files named private projects.** Files documented as repo-agnostic named
  `serenity_api`, `serenity_ui`, `$HOME/code/serenity/...` and a specific `alpha`
  branch — one developer's layout, in a module meant for a teammate to clone.
- **Drift was the maintenance cost.** A copied file that differs from its canonical
  version is a bug nobody sees until someone reads both.

The rule-file system removes all three: rules live in one place and are read on
demand through a router, the switch block makes per-repo behaviour explicit, and
nothing is copied into a repo.

## What replaced what

| Retired module | Now |
| --- | --- |
| `tdd.md` | `rules/gates/TDD.md` (+ `rules/rust/TDD.md`, `rules/angular/TDD.md`) |
| `workflow.md` | `rules/gates/PLAN_PHASES.md` (phases, closing phases) + `rules/gates/TICKETS.md` (gates, preconditions, PR) |
| `tickets.md` | `rules/gates/TICKETS.md` (generic; the repo's own `AGENTS.md` carries its tool and paths) |
| `branching.md` | `rules/gates/TICKETS.md` (branch naming, PR linking, release flow) |
| `worktrees.md` | `rules/WORKTREES.md` |
| `validation.md` | `rules/gates/VALIDATION.md` |
| `forms.md` | `rules/gates/FORMS.md` |
| `code-review.md` | `rules/gates/CODE_REVIEW.md` (+ `rules/rust/CODE_REVIEW.md`, `rules/angular/CODE_REVIEW.md`) |
| `rust.md` | `rules/rust/RUST.md` → `API_HTTP.md`, `CLI.md`, `TDD.md`, `CODE_REVIEW.md` |
| `angular.md` | `rules/angular/ANGULAR.md` → `PRIMENG.md`, `TDD.md`, `CODE_REVIEW.md` |
| `agent-rules.md` | `AI/AGENTS.md` (the invariants that survive every switch) |
| `security.md` | `rules/gates/SECURITY.md` |
| `PLAN_TEMPLATE.md` | `rules/gates/PLAN_PHASES.md` (the skeleton is in that file) |
| `README.md` | `../rules/README.md` |

## Migrating a repo

A repo that vendored these keeps working — its committed `.agents/*` files are its
own. Migrating means, per repo:

1. Add the frontmatter switch block to its `AGENTS.md` (`workflow:` preset plus any
   override) and a `rules:` list.
2. Replace the vendored lifecycle modules with the repo's own routing table: which
   rule file applies to which path, and what is deliberately **not** used there.
3. Delete the vendored copies of what a shared rule file now owns; keep and extend
   the ones that carry the repo's concrete wiring — its error types, its ports, its
   commands, its Definition of Done.
4. Add `.agents/local.md` (gitignored; `git check-ignore -v .agents/local.md`
   proves it) for this machine's overrides.

Repos migrate one at a time, deliberately. Until a repo migrates, its vendored
copies are authoritative **for that repo** — do not edit them here expecting an
effect there.
