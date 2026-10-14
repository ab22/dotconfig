---
description: Reviewing Angular and PrimeNG
---

> **Read this from `angular/ANGULAR.md` when reviewing an Angular change.**

# Reviewing Angular and PrimeNG

**Load the `code-review-and-quality` skill first.** It owns the method — the five
axes, the severity labels, the structural remedies. This file adds the
Angular-specific defects, and the PrimeNG traps that only a running app reveals.

## Change detection

- **Missing `ChangeDetectionStrategy.OnPush`.** A default-strategy component
  re-renders on every event in the app, and it hides the real bug: something relies
  on that re-render to show fresh data.
- **Mutating an input object or array in place** under `OnPush`. Push a new
  reference, or the view never updates and the developer "fixes" it by injecting
  `ChangeDetectorRef`.
- **`ChangeDetectorRef.detectChanges()` as a remedy.** It is a symptom; find the
  mutation or the missing signal first. `markForCheck()` in an async callback is
  legitimate — a bare `detectChanges()` in a setter is not.
- **A method call in a template** (`{{ compute(x) }}`, `[class]="isActive(i)"`).
  It runs every cycle. `computed()` or a field.

## State and subscriptions

- **A manual `.subscribe()` with no `takeUntilDestroyed()` or `toSignal()`.** This
  is the leak class; the fix costs one operator.
- **`BehaviorSubject` where a signal belongs.** If nothing needs the observable
  contract — no `switchMap`, no `combineLatest` — the subject is ceremony plus a
  teardown obligation.
- **A derived value stored in a field.** Two sources of truth, and one path will
  forget to update it. `computed()`.
- **A feature's state in a shared service.** The shared module stops being
  reusable the first time a feature writes into it.
- **`firstValueFrom`/`lastValueFrom` inside a template-driven path** where a signal
  or `resource()` would carry loading and error state as types rather than as three
  booleans that can disagree.

## Forms

- **`new FormGroup({})` with no type parameter** — the mapper's contract becomes
  `any` and the absent-vs-empty rules stop being checkable.
- **A validator in the submit handler.** The error cannot be shown next to the
  field, so the user gets one message at the bottom.
- **The component deciding whether an untouched field is omitted or `null`.** That
  decision belongs to the mapper; see the `gates/VALIDATION.md` file.
- **Reading `form.value` instead of `form.getRawValue()`** on a form with disabled
  controls — the disabled value silently disappears.
- Any form change at all: read the `gates/FORMS.md` file and check the label, sizing
  and entry rules against it.

## Templates and DOM

- **A control with no accessible name** — an icon-only button without
  `aria-label`, a field whose label does not point at it.
- **`innerHTML` on data that came from outside the app.** The sanitizer is the
  last line, not the first.
- **`@for` without `track`.** Angular re-creates the DOM for the whole list on any
  change, which also destroys focus and scroll position.
- **An `*ngIf` + `async` pipe chain that re-subscribes** because the pipe sits
  inside a template that is re-created.
- **Meaning carried by colour alone.**

## Tests

- **A test that asserts after a missing `detectChanges()`** on an `OnPush`
  component — it passes against stale DOM and proves nothing.
- **`setTimeout` in a test** rather than `await fixture.whenStable()`. A delay
  instead of a signal is a flake with a schedule.
- **Asserting on a private method** rather than the component's DOM behaviour.
- **A browser-based suite that reports success without running.** Karma's exit code
  is `0` when its output is piped, so a suite that never started looks green — check
  for the runner's own `TOTAL: … SUCCESS` line. The `windows/WINDOWS.md` and `macos/MACOS.md`
  carry the sandbox detail.
- **No test for the changed behaviour** — and under `tdd: on`, no test first. See
  the `gates/TDD.md` file.

## PrimeNG specifically

- **An API used from memory rather than read from `node_modules`.** PrimeNG's
  signatures, inputs and template requirements move between majors. Verify against
  the installed `.d.ts`; a remembered API is the most common source of wasted time
  in this stack.
- **A `p-floatLabel` whose input is not a sibling.** It renders, and the label sits
  in the wrong place.
- **A `p-dropdown`/`p-select` bound to a collection it loads in full.** Filter
  tables page with `onLazyLoad`; a select pages with its own virtual scroll. Loading
  everything is fine at 20 rows and a defect at 20,000.
- **A control whose blur handler writes back**, swallowing the click that caused the
  blur — the classic "I clicked Save and it submitted the old value".
- **A `confirm()` resolved by template rather than by the config object** — the
  two paths behave differently; check which one the version installed here uses.
- **A custom control that does not implement the form control contract**
  (`ControlValueAccessor` / `NG_VALUE_ACCESSOR`), so its validation and its
  write-back are invisible to the form.
- Read `PRIMENG.md` for the symptom-to-cause table before debugging any
  of these from first principles — each has already cost a session.
