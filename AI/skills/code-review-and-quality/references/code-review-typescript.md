# Code Review — TypeScript (Angular 17 + PrimeNG)

The Angular/TypeScript adaptation of the five review axes, consumed by the
`code-review-and-quality` skill.

This file is **repo-agnostic**: it names the defects a reviewer of *any*
Angular/PrimeNG application must look for. Each repository's own
`.agents/ANGULAR.md` carries its concrete wiring and **wins over this file**
where they differ.

## Correctness

- **Verify every PrimeNG API against the installed version**, not against the
  documentation for the latest major. Check `node_modules/primeng` before use.
  A component introduced in a later major is a **defect, not a nit** — it will
  not compile. Typical traps: `p-inputTags` (v19+; use `p-chips` on v17) and
  `p-tabs` / `p-tablist` / `p-tabpanels` (v18+; use `p-tabView` / `p-tabPanel`).
- **A reference template from a newer major will not compile here.** Take its
  layout and styles, never its component API.
- **`strictTemplates` is on**: no `any`, prefer an `enum` over inline string
  literals, and mirror backend enums in the UI so the two cannot drift.
- Subscriptions are torn down on destroy; no work is scheduled after destroy.
- Impossible states are made unrepresentable in the type rather than guarded at
  every use site.

## Boundaries — absence, `null` and `undefined`

- **The mapper decides, not the component.** Untouched → the key is **omitted**;
  cleared → an explicit **`null`**. A component that decides this itself is a
  finding.
- `||` needs a reason; **`??` is the default**. On a boolean or a number, `||` is
  a bug — `false` and `0` are legitimate values.
- The model type must say a field can be missing (`field?: T | null`) so the
  compiler forces the caller to handle it.
- **`PATCH` semantics:** omitting a section is not the same as clearing it. A
  mapper returning `undefined` means "leave alone"; clearing must send `null`.
- Red flags: `x || undefined`, `x || 0`, `x ?? ''` on a field whose type allows
  `null`; a control that is never touched but still serializes as empty.

## Internationalisation

- **Every user-visible string goes through the translation catalogue.** A
  hardcoded literal is a finding.
- New keys are added to the catalogue, not inlined; removing the last use of a
  key is part of the change.
- Interpolation and pluralisation go through the translation mechanism, not
  string concatenation.

## Architecture

- Follow the repository's module layout: feature folders
  (`pages/`, `components/`, `helpers/`, `enums/`, `models/`) with genuinely
  shared helpers in a shared folder. Use the configured path aliases rather than
  deep relative imports.
- **Feature-specific logic must not leak into a shared module.** Reuse the
  canonical helper instead of writing a near-duplicate.
- **Do not "clean up" the version-specific workarounds.** They look like cruft
  and are not: under `OnPush`, an animation `done` callback can fire *outside the
  Angular zone*, which is the shared root cause of a dialog mask that stays on
  `<body>`, of `ng-animating` freezing, and of a preview overlay that never
  dismisses. A fix that ignores the zone will look correct and then fail
  intermittently. Treat these workarounds as deliberate and ask before removing
  one.
- A component that keeps its own copy of server state will drift from it; prefer
  one source of truth.

## Buttons & severity

- `p-button` severity classes carry meaning, and the mapping must be consistent
  across the application: default = primary action; `secondary` = a
  non-emphasized alternative; `text` + `secondary` = a quiet dismiss (Cancel,
  Close, Back) and a confirm dialog's **reject**; `danger` = destructive;
  `success` = completion.
- **A dialog's accept and reject must never look alike.** If you cannot tell them
  apart at a glance, the dialog is wrong.
- A destructive *trigger* button is outlined-danger unless it stands alone with
  no primary sibling.
- When changing these classes, check both the confirm-dialog config and the
  trigger buttons.

## Performance

- Unnecessary re-renders; `detectChanges()` or a manual change-detection call in
  a loop; work inside a template binding that should be pure.
- Long lists rendered without `trackBy` (or the modern equivalent) rebuild every
  row on a change.
- Unbounded lists without pagination or virtual scrolling.
- Payload size: a list endpoint returning full objects where the view needs a
  handful of fields.

## Security

- The auth token is attached by the interceptor and read from storage — never
  logged, never placed in a URL.
- **Nothing in the frontend bundle is secret.** Treat environment files as
  public.
- Avoid bypassing the built-in sanitiser (`bypassSecurityTrust*`) without a
  documented, reviewed reason.
- Presigned URLs are short-lived by design: handle expiry with a refresh, and
  fall back to a static local placeholder rather than a broken image.

## Tests

- Unit tests run under the repository's runner (Karma/Jasmine here), in a
  non-watch invocation so the gate terminates.
- **Playwright / E2E specs rely on stable selectors** — ids or test ids. A spec
  that depends on translated text or CSS structure is a finding.
- Keyboard-driven components need a **full `KeyboardEvent`** (both `key` and
  `code`); dispatching `key` alone does not trigger them.
- If `locator.click()` hangs waiting for stability, dispatch a bubbling
  `MouseEvent` from the page context instead.
- **The API E2E suite is the source of truth for the API contract** — check
  integration changes against it rather than against assumptions.
- Verify in a real browser after a **fresh reload**: the dev-server console keeps
  stale errors, so a clean console there is not evidence.

## Red flags

- A PrimeNG component or property from a later major version.
- A hardcoded user-visible string instead of a translation key.
- `||` applied to a boolean or a number.
- A component (rather than the mapper) deciding whether to omit or null a field.
- A version-specific workaround deleted as "cleanup".
- A confirm dialog whose accept and reject look the same.
- A Playwright spec selecting on translated text or DOM structure.
- A feature's logic inlined into a shared module.
