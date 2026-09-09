# Agent working rules (shared)

Cross-cutting behaviour rules for AI coding agents, shared across repos in this
workspace. Repo-specific entry points (`AGENTS.md`) list the rules that matter
most there; this module is the canonical, general version.

## Defaults

- **When in doubt, never assume — ask for guidance.**
- Break work into **phases**, and execute phases **one at a time**.
- Prefer **Test-Driven Development** (see `tdd.md`): tests first, `TDD
  CHECKPOINT` commit, then implement to green.
- **Do not create commits for the user** — they review and commit their own
  work (the `TDD CHECKPOINT` commit is the documented exception).
- Keep answers and changes minimal and focused on the request.

## Documentation & tickets

- A plan/design/wireframe doc is a **ticket**, not a `docs/` file — file it with
  `gh-plan new <doc>` (see `tickets.md`) and delete the local copy.
- Plans affecting both `serenity_api` and `serenity_ui` become **two** tickets
  (one per repo), each embedding the same document, cross-linked.
- Start implementation from a ticket on `feat/<prefix>-<id>-<slug>` and open
  the PR with `gh-plan pr` so the issue is linked (`Closes #<id>`) — see
  `branching.md`.
- The **ticket/plan is the source of truth**; don't silently re-derive design
  decisions recorded there.

## Verification

- After changing code, run the repo's build/tests and fix any errors before
  finishing (UI: `npx ng build --configuration development` + fresh browser
  reload; API: `task test` / `cargo check`).
- Prefer repeatable checks (tests, E2E specs) over one-off manual steps.
- Treat E2E suites as the API/UI contract where the repo says so.

## Repos at a glance (workspace)

| Repo | Stack | Local path | Default branch |
| --- | --- | --- | --- |
| serenity_api | Rust (Axum + sqlx/Postgres) | `/Users/abe/code/serenity_api` | `main` |
| serenity_ui | Angular 17 + PrimeNG, Spanish-only | `/Users/abe/code/serenity_ui` | `main` |
| dotconfig | shared dotfiles + `AI/` tooling + agent modules | `/Users/abe/code/dotconfig` | `main` |

Release flow: **alpha (dev) → beta (staging) → main (production)**. Feature PRs
target `alpha`; releases promote up the chain (`alpha → beta → main`).
