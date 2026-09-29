# Forms, fields and pickers

Framework-agnostic rules for any form, field or picker UI, whatever the stack.
They were extracted while unifying the forms in `serenity_ui` (tickets #33, #34
and #35). That repo's `.agents/ANGULAR.md` holds the Angular/PrimeNG wiring — the
shared component, the measured widths, the field-height pin — and points here for
the principles. **Canonical reference: not vendored into repos, so a repo never
carries a copy that can drift.**

## Anatomy and labels

- **Every field has a persistent, external label.** Never a label that lives inside
  the control and disappears behind its value: on a long form the user loses track
  of which row they are reading.
- **Never mix label placements inside one form.** Half horizontal, half stacked
  reads as two different forms glued together. Convert a section as a whole,
  including the controls that are not text fields.
- **A blank control id must not emit an empty `for`.** It points at nothing and
  reads as an unlabelled control; omit the attribute instead.
- **The required marker belongs to the label, the announcement to the control.**
  Mark the asterisk decorative and put `aria-required` on the control itself,
  which the control's own owner writes.

## Sizing

- **Size the control to its data.** Long text fills the row; short data (counts,
  codes, money, percentages, dates) gets a cap. A spinner or calendar affordance
  stranded at the far end of a full-width row is a long eye-and-pointer trip from
  the value the user is reading — the row may look emptier, but the control is
  where the eye already is.
- **A cap on the control must not cap the message under it.** Error and help text
  belong to the whole column: capping the column squeezes a sentence into a ribbon
  of short lines. Cap the control element, not the box that holds the text.
- **A narrowed control must still fit its own content:** its format hint
  (`dd/mm/aaaa`, `100 %`), any unit suffix inside the field, and the affordances it
  renders (spinner buttons, a calendar trigger, a dropdown chevron). Measure the
  hint rather than guessing, and remember a host narrower than what it renders
  clips its own label.
- **Size the label column to the longest label** so no label wraps, and cap the
  form to its container rather than to the monitor.

## Entry behaviour

- **Allow typing in a date field,** and parse before discarding: an unparseable
  value stays on screen and is reported, never silently cleared.
- **A picker opens from its affordance, never on focus.** Opening on focus steals
  the caret and stops the user typing.
- **Make a distant value directly reachable** (a year picker, not a decade of
  paging).

## Consuming the choices

- **Keep every option reachable when you bound a list.** Grey out or group the
  implausible ones; do not silently remove them, and never lead with a value nobody
  chose (midnight as a clinic's opening time). Removal loses spatial consistency and
  hides genuinely valid cases such as night shifts.
- **A long, undifferentiated list is the wrong control for a familiar value.** For
  enumerated, familiar choices prefer a bounded picker or grouped options over
  dozens of identical rows.

## Consistency

- **Control heights must match across a form,** including controls that do not
  render the same inner element (spinners, multi-selects, chips). When the field
  height changes, re-check every control type.
- **An empty or whitespace-only message renders nothing,** rather than an empty
  element that still takes up space.
