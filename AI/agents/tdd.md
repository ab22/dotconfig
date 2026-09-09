# TDD discipline

Shared, language-agnostic Test-Driven Development rules used across repos in
this workspace (they complement repo-specific guidance such as
`serenity_api/.agents/TESTING.md`).

## The cycle

1. **Write a failing test first** that expresses the behaviour you want (unit,
   integration, or E2E — whatever fits the repo's test setup).
2. **Commit the failing test(s)** alone with the message **`TDD CHECKPOINT`** so
   the red state is reviewable and easy to return to.
3. **Implement** the smallest change that makes the test pass (no more).
4. **Refactor** if needed; re-run the suite to green.
5. Only then move to the next behaviour.

## Working rules

- Implement work **in phases, one at a time** — finish and verify a phase before
  starting the next.
- When implementing from a ticket, follow its embedded plan's phase order and do
  not re-derive the design.
- **Do not create git commits for the user** — the user reviews and creates
  their own commits. The only exception in this flow is the intermediate
  `TDD CHECKPOINT` commit, which the repo convention already calls for.
- Run the repo's verification before calling a task done (build + tests; for
  the UI also `npx ng build --configuration development`; for the API the full
  `task test` suite). Rely on those results, not stale editor output.
- If the existing tests are the spec (e.g. an API E2E suite that is the source
  of truth), treat them as the contract and keep them green.

## Why

Tests-first keeps the work provable at each step, makes review cheap, and gives
the implementing agent an unambiguous definition of done.
