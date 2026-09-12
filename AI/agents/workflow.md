# Feature workflow: plan → implement → review → PR

Shared, repo-agnostic lifecycle for non-trivial work. Repos adopt this module as
`.agents/WORKFLOW.md`; their own `AGENTS.md` supplies the concrete commands
(test tasks, ticket tooling, paths) for each stage.

The three stages are **gated**: do not advance until the gate is passed. The
user owns the planning gate and the review gate.

```
Plan ──[user approves plan + failing tests]──▶ Implement ──[user reviews]──▶ PR
```

## 1. Planning

Entering planning means producing a **plan document**, which becomes the ticket
(see `tickets.md`). The document must contain:

- A `## Phases` section: numbered phases, one concern each, with the concrete
  steps and the verification command that proves the phase is done.
- **Test-Driven Design as one of the first phases.** Write the unit tests for
  the behaviour before the implementation, run them, and confirm they fail for
  the expected reason. Then hand them to the user — this is the planning gate:
  **do not implement until the user approves the tests** (see `tdd.md`).
- **Mandatory closing phases**, added even when the user does not ask for them,
  adapted to what the plan actually touches:
  - **more unit tests** — edge cases, boundaries, and regressions beyond the
    tests-first phase;
  - **integration tests** — the pieces working together against real
    infrastructure;
  - **Postman collection updates** — when the plan adds or changes HTTP
    endpoints, auth headers, or response fields;
  - **end-to-end tests** — the repo's E2E suite when the change is observable
    through the public interface (UI plans substitute their Karma/Playwright
    equivalents).

A plan that changes no behaviour still ends with an explicit verification phase.

## 2. Implementation

### Preconditions (all must hold before writing code)

1. **The ticket exists.** Every plan is a GitHub issue. If the user asks to pick
   up a plan and no issue exists, create it first — `gh-plan new <doc>` embeds
   the full document (`tickets.md`) — and only then branch.
2. **The base branch is current.** Feature work branches from `alpha` (the dev
   branch) unless the user specifies otherwise:
   `git fetch origin && git checkout alpha && git pull origin alpha`.
3. **The working tree is safe to branch from.** If the pull produces conflicts,
   or there are uncommitted/unstaged files, **stop and notify the user**. The
   user resolves them; do not stash, discard, or force anything. Wait until the
   user reports where things stand, then continue.
4. **The branch matches the ticket.** Create it with the repo's tooling
   (`gh-plan branch <api|ui> <id> --create`) so the name is
   `feat/<prefix>-<id>-<slug>` (see `branching.md`).

### Execution

- Execute the plan's phases **one at a time**; verify each phase before starting
  the next (see `tdd.md`).
- Keep the ticket's phase order; do not silently re-derive the design.
- **The user makes all commits** — see `tdd.md`.

## 3. Review and PR

- When implementation is done, **stop**. Do not commit, do not push, and do not
  open a PR yet. Report what changed, what was verified, and anything left open,
  then wait for the user to review and commit.
- Apply review feedback and re-run verification after every change.
- **Only after the user confirms everything is good**, push the feature branch
  and open the PR against the existing issue. Push the branch the PR opens from —
  never `alpha`, `beta`, or `main`:
  - the PR body must link the ticket (`Closes #<id>`; `gh-plan pr` pre-fills it),
  - the base branch is `alpha` (or whatever the user specified),
  - cross-repo plans add the companion ticket line (`branching.md`).
- **If there is no issue, do not open a PR.** Notify the user and wait for
  instructions.

## Gate checklist

| Stage | Gate | Owner |
| --- | --- | --- |
| Planning | Plan has phases; TDD tests written, seen red, and approved | user |
| Implementation | Ticket exists; `alpha` synced; tree clean; phases verified | agent |
| Review | Work reviewed and explicitly approved | user |
| PR | PR opened, linked to the issue, based on `alpha` | agent |
