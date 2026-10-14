---
description: Angular-specific testing rules — read with the general tests-first gate. TestBed setup, why a fixed timeout is a flake, the OnPush detectChanges trap, whenStable, and the browser suite's false green under a confined sandbox.
---

> **Read this when the `tdd` switch is on and the code under test is Angular.**

# Angular and TDD

**Read [`../gates/TDD.md`](../gates/TDD.md) first.** It owns the gate: write the
failing test, run it, confirm it fails *for the expected reason*, hand the red
output to the user and wait. Nothing here replaces that, and where the two
disagree the gate wins.

This file adds only what is specific to Angular.

## Test the behaviour through the DOM

- **Assert on what the user sees**, not on the component's private methods or its
  fields. A test against `component.save()` passes while the button is unwired.
- Use the component's accessible surface: the rendered label, the button's text,
  the `aria-label`. A test that finds a control by CSS class breaks on a restyle
  and proves nothing about whether a person could use it.
- **A `fixture.detectChanges()` that never runs is the classic false green.** Under
  `OnPush` the view does not update on its own, so a test that sets an input and
  asserts immediately is asserting against stale DOM. Change the input, then
  `fixture.detectChanges()`, then assert.

## Async work

- **`await fixture.whenStable()`** after anything async — a resolved HTTP stub, a
  signal that settles, a navigation.
- **Never `setTimeout` in a test.** A fixed delay is a flake with a schedule: it
  passes on your machine and fails on CI. If you believe you need a delay, the
  thing you are waiting for has no observable completion — fix that instead.
- `fakeAsync`/`tick()` is right for timer-driven behaviour, and it makes the
  passage of time explicit rather than real.

## Setup

- **`TestBed` only for what the test needs.** A test that configures the whole app
  module is slow and fails for reasons unrelated to the behaviour under test.
- **`HttpTestingController` over a hand-rolled spy** for HTTP: it can assert that
  no unexpected request was made, which a spy cannot.
- **Override the provider, not the component's internals.** If a test has to reach
  inside the component to make it pass, the dependency is not injected.
- Standalone components: import the component under test directly rather than
  declaring it in a throwaway module.

## Boundary cases

The [`../gates/VALIDATION.md`](../gates/VALIDATION.md) set applies to every input,
and in a form it has a UI consequence worth asserting separately:

- untouched → the key is **omitted** from the request body;
- cleared → the key is sent as **`null`**;
- `""` / whitespace-only on a required field → the form is invalid and the error is
  visible **next to the field**, not in a summary at the bottom.

Assert the request body shape, not just the form's validity — the mapper is where
the bug lives.

## The browser suite can lie

Read [`../windows/WINDOWS.md`](../windows/WINDOWS.md) or
[`../macos/MACOS.md`](../macos/MACOS.md) before trusting a browser-based run:

- **Karma's exit code is `0` when its output is piped**, so a suite that never
  started looks like a pass. **Assert on the runner's own `TOTAL: … SUCCESS` line**,
  never on the exit code alone.
- Under a confined sandbox on macOS the runner cannot start at all, and the failure
  reads as a silent no-op rather than an error.

A green run you cannot see the summary line for is not evidence.

## Running them

Use the repo's own command from its `AGENTS.md` (often a headless
`ng test --watch=false`, sometimes wrapped in a task). Run the whole suite before
calling a change done — an `OnPush` or typed-form change breaks sibling specs, and
that is what the suite is for.
