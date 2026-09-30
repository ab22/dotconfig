# Angular & PrimeNG conventions (shared)

Language-level rules for the Angular SPAs in this workspace. Repo-specific wiring
(commands, folder structure, Definition of Done) stays in the repo's own
`.agents/ANGULAR.md`, which folds these in by hand.

## Verify every PrimeNG API against the installed build

PrimeNG's docs track the latest major, and a project pinning v17 can still
receive v18 component code inside a 17.x tarball. Before depending on an input,
output, CSS class or template behaviour, read the real thing —
`node_modules/primeng/fesm2022/primeng-<component>.mjs` — and record the finding
next to the code that relies on it.

Two findings worth not re-deriving:

- `p-calendar`'s `monthNavigator` / `yearNavigator` inputs are declared but
  **deprecated no-ops** ("Navigator is always on"): there is no navigator markup
  left in the template, and the header is a month button plus a year button that
  switch to the month/year grids.
- `p-calendar`'s `[keepInvalid]="true"` is the only thing that stops it silently
  clearing text it cannot parse when the field loses focus.

## A custom form control can be its own validator

A component that renders a control can own both halves of the contract:

```ts
providers: [
  { provide: NG_VALUE_ACCESSOR, useExisting: forwardRef(() => FieldComponent), multi: true },
  { provide: NG_VALIDATORS, useExisting: forwardRef(() => FieldComponent), multi: true },
]
```

`validate()` reports the **view's** state ("the field holds text that did not
parse"), not the bound value — the value is kept deliberately usable: pin it to
the last valid value (or `null`) so nothing unusable can be serialized, and let
validity, not the value, block submit. Implement `registerOnValidatorChange` and
call it whenever validity changes without a value change; that callback is what
re-runs the parent control's validators.

## Never let a blur write-back destroy the click that caused it

Typed input is parsed on blur. When that write goes through the value accessor it
re-renders the bound component — for `p-calendar` it rebuilds the whole open
panel. If the blur was caused by a `mousedown` inside that same panel, the browser
sees the mousedown target detached by `mouseup` and fires **no `click` at all**:
day cells, header buttons and the Today/Clear bar then silently need a second
click. Two rules follow, and both are needed:

- **Restore the model without touching the view** —
  `setValue(value, { emitEvent: false, emitModelToViewChange: false })`.
  `emitEvent: false` alone still writes the view, because Angular's `setValue`
  calls the accessor unless `emitModelToViewChange` is false; that write is what
  wipes the user's text or the open panel.
- **Keep focus in the field while its own popup is used** — a host listener that
  calls `preventDefault()` on `mousedown` when the target is inside the popup.
  Scope it to the popup: preventing the default on the input itself stops the
  field from ever taking focus.

## Text entry that a user can trust

- **Allow typing**, even when a picker exists. A calendar must never be the only
  way to enter a date, and a birth date is usually faster to type than to find.
- **Parse on blur through one shared, pure parser**, not once per component, and
  accept the separators people actually use (`/ - .` and space, with or without
  leading zeros).
- **Never discard what was typed.** An unparseable value stays on screen, is
  reported next to the field, and marks the control invalid so it cannot submit.
- **Never open a picker on focus.** Focus (including Tab) must leave the keyboard
  in the field — `[showOnFocus]="false"` plus the explicit icon trigger.
- **Reject impossible calendar dates** by round-tripping the parsed parts back
  through `Date` (`31/02`, a 29 February outside a leap year); a parser that
  guesses rolls them forward instead.

## An invalid field must also *look* invalid

Rendering the message is only half of it. PrimeNG themes paint the border with
**two** classes — `.p-inputtext.ng-dirty.ng-invalid` for plain inputs, and
`p-calendar.ng-dirty.ng-invalid > .p-calendar > .p-inputtext` for calendars — so a
field carrying only one of them stays grey, and extra specificity cannot rescue
it. Note also that `ng-invalid` lands on the element that carries the control,
which for a wrapper component is the wrapper's host, not the inner input.

When a component validates more than its bound value (e.g. "the text that did not
parse"), mirror the verdict onto the controls it binds, and mark them dirty when
the underlying library leaves them pristine. Verify the result in a browser on the
settled computed style, not mid-transition: a `border-color` transition reads as
several wrong colours before it lands.

## `p-floatLabel` floats via a sibling selector

`primeng.min.css` floats the label with
`.p-float-label .p-inputwrapper-filled ~ label`, and `.p-inputwrapper-filled`
lives on the `p-calendar`/`p-dropdown` host element. A wrapper component that
projects the label next to itself never floats — the label's sibling is the
wrapper. So a component that owns a float label must render the control and the
`<label>` as siblings itself. A **group** of inputs cannot reuse the mechanism at
all (there is no single `p-inputwrapper`): give each sub-field its own label and
put the group label above the group.

## OnPush overlays and the animation `done` outside the zone

PrimeNG overlays that use OnPush can leave their mask (and a body overflow class)
behind when the leave animation's `done` fires outside the Angular zone. This has
bitten both the confirm dialog and the image preview. Verify overlays close
cleanly after every PrimeNG upgrade.
