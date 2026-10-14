---
description: How to write a phased plan document — the required skeleton, phases one concern at a time each with its verification command, Test-Driven Design among the first phases, and the mandatory closing phases (more unit tests, integration tests, E2E, Postman/API collection updates) that are added even when nobody asked. Use when the `plan-doc` or `closing-phases` switch is on and work needs a plan before implementation.
---

> **Read this when the `plan-doc` or `closing-phases` switch is on and you are writing a plan.**

# Plan documents and phases

Two switches, two obligations:

- **`plan-doc: on`** — non-trivial work starts with a written plan document, not
  with code.
- **`closing-phases: on`** — that plan always ends with the closing phases, added
  **even when the user did not ask for them**.

`phases: on` is the third: execute phases **one at a time**, verifying each before
starting the next.

## The plan skeleton

```markdown
# <Title>

## Context
Why this change; the behaviour today and the behaviour wanted.

## Phases

### Phase 1 — <one concern>
- steps, concrete
- **verify:** the exact command that proves this phase is done

### Phase 2 — <the next concern>
…

### Phase N — more unit tests
- edge cases, boundaries, and regressions the tests-first phase did not cover
- **verify:** the suite command, green

### Phase N+1 — integration tests
- the pieces working together against real infrastructure
- **verify:** the integration command

### Phase N+2 — end-to-end / collection updates
- the repo's E2E suite, and its API collection when endpoints changed
- **verify:** the E2E command
```

## Rules

- **One concern per phase.** A phase that does two things cannot be verified
  half-way, so a failure tells you nothing about which half broke.
- **Every phase names its verification command.** "Implement the parser" is not a
  phase; "implement the parser, `cargo test parser::` green" is.
- **Test-Driven Design is one of the first phases** when `tdd: on` — the failing
  tests, seen red, before the implementation phase. See the `gates/TDD.md` file.
- **The closing phases are mandatory under `closing-phases: on`,** adapted to what
  the plan actually touches:
  - **more unit tests** — edge cases, boundaries and regressions beyond the
    tests-first phase;
  - **integration tests** — the parts working together against real
    infrastructure;
  - **E2E tests** — the repo's own suite, when the change is observable through
    the public interface;
  - **API collection updates** — when the plan adds or changes endpoints, auth
    headers, or response fields (Postman, Bruno, `.http` files, whatever the repo
    uses).
- **A plan that changes no behaviour still ends with an explicit verification
  phase.** "Delete the dead module" is verified by the build and the suite, and
  the plan says so.
- **Do not silently re-derive the design during implementation.** The plan is the
  record. If it turns out wrong, say so and update it — do not quietly build
  something else.
- **The plan is not the ticket.** Where the repo uses the ticket workflow, file it
  and delete the local copy — see the `gates/TICKETS.md` file. A plan that lives in
  `docs/` and nowhere else is invisible to the next reader.

## Size

Match the plan to the change. A three-line fix does not need six phases; it needs
one phase and its verification. The skeleton above is the shape for work that
genuinely spans phases — the failure mode it prevents is the unphased "implement
the feature" ticket that cannot be verified until it is all done.
