# Agent working rules (shared)

Cross-cutting behaviour rules for AI coding agents, shared across repos in this
workspace. Repo-specific entry points (`AGENTS.md`) list the rules that matter
most there; this module is the canonical, general version.

## Defaults

- **When in doubt, never assume — ask for guidance.**
- Follow the shared lifecycle **plan → implement → review → PR** (`workflow.md`);
  the user owns the planning and review gates.
- Break work into **phases**, and execute phases **one at a time**.
- Prefer **Test-Driven Development** (see `tdd.md`): write the failing test, run
  it, confirm it fails for the expected reason, and hand it to the user before
  implementing.
- **The user makes all commits by default** — agents do not run `git commit`.
  The one exception is an explicit request for the *whole flow in one go*
  ("commit, push, open the PR and merge"); do not infer it from "push and merge"
  alone. There is still no checkpoint-commit exception.
- **Push and open the PR only on the user's go** — normally after they review,
  commit, and say to proceed; as part of an explicit one-go request otherwise.
  Push the feature branch the PR opens from; never push `alpha`, `beta`, or
  `main`.
- Keep answers and changes minimal and focused on the request.

## Documentation & tickets

- A plan/design/wireframe doc is a **ticket**, not a `docs/` file — file it with
  `gh-plan new <doc>` (see `tickets.md`) and delete the local copy.
- Plans affecting both `serenity_api` and `serenity_ui` become **two** tickets
  (one per repo), each embedding the same document, cross-linked.
- Plans are **split into phases** with Test-Driven Design among the first, and
  always end with the **closing phases** (more unit tests, integration tests,
  Postman/E2E updates) — see `workflow.md`.
- Before implementing: confirm the ticket exists (create it if not) and branch
  from an up-to-date `alpha`; on conflicts or a dirty tree, stop and notify the
  user (`branching.md`).
- Open the PR with `gh-plan pr` **only after the user has reviewed and approved
  the work**, and never without a ticket — see `branching.md`.
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

Release flow: **alpha (dev) → beta (staging) → main (production)**. Feature
branches are cut from `alpha` and their PRs target `alpha`; releases promote up
the chain (`alpha → beta → main`).
