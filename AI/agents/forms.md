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

## The read-only twin of a form

A record is read far more often than it is edited, and the read-only screen is
usually a different screen. These rules keep the two from drifting apart.

- **A read-only field row reuses the form's own row anatomy, in the form's own
  container** — same row element, same label column, same vertical rhythm. The
  column must line up *by construction*, not by eye: the label column is what the
  eye scans down, and data that jumps sideways when the user presses *Edit* costs
  the reader their place. A read-only screen that grows its own percentage-based
  columns is exactly the drift this rule prevents.
- **…and it follows the form's row order,** for the same reason. A read-only
  sub-heading that groups fields more readably than the form does is not worth
  inverting the sequence: someone who has learnt where a field sits in the form
  must find it in the same place.
- **A read-only row is not a field.** There is no control to label and nothing to
  validate, so it is a *different component*, not a `readonly` mode on the field
  component. A mode switch would make most of that component's inputs conditional
  (control id, required marker, error text, every error attribute) and would emit a
  label pointing at nothing. Mode switches need a named reason.
- **Project the value; do not add a plain-value input.** One string input cannot
  carry a chip list, a translated enum label, a formatted date or a derived suffix,
  so a component offering both would need a "which one wins" rule.
- **An absent value keeps its row and its filler.** Deleting the row makes two
  records structurally incomparable and makes the label column jump; showing the
  label with an explicit "empty" tells the reader the field exists and was not
  recorded, which is information. **A present-but-empty value is absent:** guard a
  collection by its length, never by truthiness — an empty list is true, so a
  truthiness check silently reports it differently from a missing one.
- **Do not let a display shorthand invent a value.** A mapping that collapses
  "not recorded" onto the first real answer (a bare truthiness ternary over a
  clearable choice, say) states something the record does not say, which is worse
  than an empty cell.

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
