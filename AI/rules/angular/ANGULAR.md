---
description: Angular and PrimeNG conventions — standalone components with OnPush, signals over manual subscriptions, typed reactive forms, and control-flow syntax. Routes to the PrimeNG trap list and to the Angular testing and review files.
---

> **Read this when working in Angular or PrimeNG.**

# Angular conventions

Read this first, then follow the rows that match the work.

| The work is… | Read next |
| --- | --- |
| a PrimeNG control, overlay, table or date picker | `angular/PRIMENG.md` — the traps, each with its symptom |
| **being tested, or written test-first** | `angular/TDD.md` — TestBed, the `OnPush` stale-DOM trap, `whenStable`, the browser suite's false green |
| **being reviewed** | `angular/CODE_REVIEW.md` — change detection, subscription leaks, form and template defects |
| anything else in Angular | this file |

The task rows are **not alternatives** to the first: a PrimeNG control written
test-first reads `angular/PRIMENG.md` **and** `angular/TDD.md`. Each task file names
the general rule it refines, and you read that general file too.

A repo's own `.agents/ANGULAR.md` carries its measured widths, its shared
components and its version pin, and **wins over this file** where they differ.
**Read the installed `package.json` version before trusting any API memory** — the
traps below exist because PrimeNG's API moves between majors.

## Components

- **Standalone components**, no `NgModule` for new work. An `NgModule` that only
  declares one component is a wrapper with no job.
- **`ChangeDetectionStrategy.OnPush` on every component.** A default-strategy
  component re-renders on every event anywhere in the app; it is also the reason a
  "just assign the property" pattern appears to work.
- **`input()` / `output()` signal APIs** over the decorators where the Angular
  version supports them. They make the input's type and requiredness explicit.
- **`inject()` over constructor parameters** for new code. It works in field
  initialisers and in functions outside the class, which is what makes a shared
  helper injectable.
- **Keep templates logic-free.** A method call in a template runs on every change
  detection cycle. Compute it once — a `computed()` signal, or a field set when the
  input changes.
- **`@if` / `@for` / `@switch`** over `*ngIf` / `*ngFor` / `*ngSwitch` where the
  version supports it. `@for` requires `track`; without it Angular re-creates DOM
  on every list change.

## State and data flow

- **Signals for local and derived state**, not a `BehaviorSubject` you subscribe to
  in the template. A signal needs no teardown, which removes the leak class
  entirely.
- **`computed()` for anything derived.** Storing a derived value means two sources
  of truth and a bug the first time one path forgets to update it.
- **Never subscribe in the template** (`| async` is fine; `.subscribe()` is not).
  A manual subscription needs an owner and a teardown.
- **`takeUntilDestroyed()`** for every manual subscription, or `toSignal()`. The
  `ngOnDestroy` + `Subject` + `takeUntil` boilerplate is obsolete; new code should
  not add it.
- **`httpResource` / `resource()`** for request-shaped state where available: it
  gives loading, error and value as one typed object instead of three booleans that
  can disagree.
- **A component's inputs are not a place to put global state.** If two sibling
  components both need it, it belongs in a service.

## Forms

- **Typed reactive forms** (`FormGroup<T>`), never `new FormGroup({})` with implicit
  `any`. The type is what makes the mapper in the `gates/VALIDATION.md` file checkable.
- **The mapper decides absent vs empty** — untouched means the key is omitted,
  cleared means `null`. Components do not decide. See the `gates/VALIDATION.md` file.
- **Validators live with the field definition**, not in the submit handler. A
  submit-time check cannot show the error next to the field.
- **Disable, do not hide, a control the user may need to see.** A field that
  vanishes makes the form's shape change under the user.
- Read the `gates/FORMS.md` file before building or changing any form, field or picker
  — it owns the label, sizing and entry rules.

## Services and DI

- **`providedIn: 'root'`** unless the service genuinely needs a component's
  lifetime, in which case it is `providers:` on that component and the reason is
  written down.
- **One HTTP concern per service**, and the service returns typed observables or
  signals — not `any`, and not a raw `HttpResponse` the caller must unwrap.
- **A feature's state service is not a shared service.** Moving feature logic into
  a shared module is how a shared module stops being reusable.

## Templates and accessibility

- **A control has an accessible name.** An icon-only button needs `aria-label`; a
  field needs the label rules in `gates/FORMS.md`.
- **`aria-live` for content that changes without navigation** — a save result, an
  error summary, a count that matters.
- **Do not encode meaning in colour alone.** Pair it with text or an icon.
- **Never `innerHTML` on untrusted data.** Angular's sanitizer is the last line,
  not the first.

## Tests

- **Test the component's behaviour through the DOM**, not its private methods.
- **A `fixture.detectChanges()` assertion that never runs** because the change
  detection strategy is `OnPush` — an `OnPush` component in a test needs an explicit
  `fixture.detectChanges()` after the input changes, or the test asserts on stale
  DOM.
- **Async work needs `await fixture.whenStable()`** rather than a fixed timeout; a
  `setTimeout` in a test is a flake with a delay.
- **The browser-based suite may not start at all in a confined sandbox** and may
  report success anyway if its output is piped. Check for the run's own success
  line, not the exit code. The `windows/WINDOWS.md` and `macos/MACOS.md` carry the detail.

## Version discipline

PrimeNG, Angular and their peer dependencies move together. Before using any API
you have not verified in this checkout:

1. read the installed version in `package.json` / the lockfile;
2. check the actual signature in `node_modules` (`.d.ts`) rather than from memory;
3. if it is missing, that is the answer — do not "fix" it by upgrading inside an
   unrelated change.

A remembered API from a different major version is the single most common source of
wasted time in this stack.
