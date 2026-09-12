# <Plan title>

Repos: api            <!-- api | ui | both — required so gh-plan files in the right repo -->

## Goal

<One paragraph: the problem, and the observable outcome that means it is solved.>

## Scope

- **In scope:** <the surfaces this plan changes.>
- **Out of scope:** <what this plan deliberately does not touch.>

## Design decisions

<The choices already made, with the reasoning. Record anything a future reader
would otherwise have to re-derive.>

---

## Phases

Phases are executed **one at a time**; finish and verify one before starting the
next. Phase 1 is Test-Driven Design. The closing phases are mandatory — keep
them even when the user did not ask for them.

### Phase 1 — Tests first (TDD)

- [ ] Write the failing unit tests for <behaviour>.
- [ ] Run `<unit command>` and confirm they fail for the expected reason.
- [ ] **Hand the failing tests to the user and wait for approval.**
- [ ] Implement the smallest change that makes them pass.
- [ ] Run `<unit command>` — green.

### Phase 2 — <next behaviour>

- [ ] <steps>
- [ ] Verify with `<command>`.

<!-- Add one phase per behaviour/slice. Do not merge unrelated concerns. -->

### Phase N-2 — More unit tests

- [ ] Edge cases, boundaries, and regressions not covered by Phase 1.
- [ ] Run `<unit command>`.

### Phase N-1 — Integration tests

- [ ] Cover the pieces working together with `<integration command>`.

### Phase N — E2E, Postman, verification

- [ ] Run `<e2e command>` if the change is observable through the public interface.
- [ ] Update the Postman collection if the HTTP surface changed.
- [ ] Run `<verify command>` — the repo's Definition of Done.

---

## Verification

<The exact commands that prove this plan is done, in the order they should run.>

## Risks / follow-ups

<What could go wrong; what is deliberately deferred to a later plan.>
