# TDD discipline

Shared, language-agnostic Test-Driven Development rules used across repos in
this workspace (they complement repo-specific guidance such as
`serenity_api/.agents/TESTING.md`).

## The cycle

1. **Write a failing test first** that expresses the behaviour you want (unit,
   integration, or E2E — whatever fits the repo's test setup).
2. **Run it and confirm it fails for the expected reason** — not because of a
   typo, a missing import, or an unrelated compile error. Capture the red output.
3. **Hand the failing tests to the user** with that red output and a one-line
   summary of what they assert, then **wait**. This is the planning gate: do not
   implement until the user approves.
4. **Implement** the smallest change that makes the test pass (no more).
5. **Refactor** if needed; re-run the suite to green.
6. Only then move to the next behaviour.

Tests-first is not a formality: production code must never be written for a
behaviour that has no failing test.

## Commits: the user owns all of them

- **The user makes every commit.** Agents must not run `git commit`, `git push`,
  or `git tag` — there is **no `TDD CHECKPOINT` exception**. If a red test is
  worth checkpointing, hand it to the user and let them decide whether to commit.
- When a phase reaches green, leave the working tree for the user to review, and
  report which files changed and the verification results.

## Working rules

- Implement work **in phases, one at a time** — finish and verify a phase before
  starting the next.
- When implementing from a ticket, follow its embedded plan's phase order and do
  not re-derive the design.
- Run the repo's verification before calling a task done (build + tests; for
  the UI also `npx ng build --configuration development`; for the API the full
  `task test` suite). Rely on those results, not stale editor output.
- If the existing tests are the spec (e.g. an API E2E suite that is the source
  of truth), treat them as the contract and keep them green.

## Why

Tests-first keeps the work provable at each step, makes review cheap, and gives
the implementing agent an unambiguous definition of done. Pausing at the red
state lets the user validate the contract before any implementation exists.
