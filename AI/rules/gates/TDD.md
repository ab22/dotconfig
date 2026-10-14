---
description: The tests-first gate — write the failing test, run it, confirm it fails for the expected reason, hand the red output to the user and wait for approval before implementing. Covers the red-green-refactor loop, the invalid/empty/boundary cases every input's tests must include, and what to do when the spec is silent. Use when the `tdd` switch is on and you are about to write or change behaviour, fix a bug, or add logic.
---

> **Read this when the `tdd` switch is on and you are about to write or change behaviour.**

# TDD gate

Load the `test-driven-development` skill for the general red-green-refactor
method. This file is the **gate** the repo's `tdd: on` switch turns on: what must
exist, and in what order, before production code is written.

If `tdd: off`, this gate does not run — do not invoke it, and do not write a test
the repo did not ask for. If the work genuinely needs tests and the switch is
off, **say so and ask**; do not decide unilaterally.

## The cycle

1. **Write a failing test first** that expresses the behaviour you want (unit,
   integration, or E2E — whatever fits the repo's test setup).
2. **Run it and confirm it fails for the expected reason** — not a typo, a missing
   import, or an unrelated compile error. Capture the red output.
3. **Hand the failing tests to the user** with that red output and a one-line
   summary of what they assert, then **wait**. This is the planning gate: do not
   implement until the user approves.
4. **Implement** the smallest change that makes the test pass — no more.
5. **Refactor** if needed; re-run the suite to green.
6. Only then move to the next behaviour.

Production code must never be written for a behaviour that has no failing test.

**A bug fix starts with the test.** The regression test comes first, and it must
fail against the current code for the reason the bug describes. A fix with no
failing-first test is not done — you cannot show the bug was ever there.

## Cover the invalid and empty path

A test set that proves only the happy path proves the example, not the behaviour.
Every change's tests include the values its inputs can actually take:

- **empty and whitespace-only** — `""`, `"   "`, `"\t\n"`;
- **absent vs `null`** — the key omitted, and the key explicitly `null`, wherever
  the contract tells them apart (load `gates/VALIDATION.md` for the boundary rules);
- **wrong type or shape** — a number where a string belongs, an unknown enum
  value, a malformed date, a value longer than the column or the limit;
- **boundaries** — the value exactly on each limit, and one step outside it.

**If the ticket or spec does not say what should happen for those values, ask the
person who owns the ticket — before writing the test.** Do not invent the
contract, and do not quietly assert today's behaviour: *"the API answers 500
today, so 500 is the expectation"* is how a bug becomes the specification. Record
the answer in the ticket so the decision is reviewable and the next reader does
not re-litigate it.

The red-state hand-off names which invalid, empty and boundary cases the tests
cover, and which ones the ticket left undefined.

## The red-state hand-off

Report, in this order:

1. the test file(s) and the behaviour each new test asserts;
2. the **exact command** you ran;
3. the red output, verbatim — the failure, not a summary of it;
4. which invalid/empty/boundary cases are covered, and which the ticket left
   undefined;
5. then stop and wait.

## Working rules

- Implement work **one behavioural step at a time**; a test that covers three
  behaviours is three tests.
- Follow the plan's phase order when there is one; do not re-derive the design.
- **Run the repo's own verification** before calling anything done. Rely on that
  result, not stale editor or watcher output.
- When the existing tests *are* the spec (an E2E suite that is the source of
  truth), treat them as the contract and keep them green.
- Leave the working tree for the user to review at the gate. The user owns
  commits — see the global baseline.

## Why

Tests-first keeps the work provable at each step, makes review cheap, and gives
the implementing agent an unambiguous definition of done. Pausing at the red
state lets the user validate the contract before any implementation exists — which
is the cheapest moment to discover the contract is wrong.
