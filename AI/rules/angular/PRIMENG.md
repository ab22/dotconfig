---
description: PrimeNG — the traps, by symptom
---

> **Read this from `angular/ANGULAR.md` before touching any PrimeNG control, overlay or table.**

# PrimeNG — the traps, by symptom

Each entry starts from what you see. These are the ones that have already cost
sessions; the version you have is named in the repo's `package.json`, and **the
installed `.d.ts` is the source of truth**, not this file and not your memory of a
different major.

## The label floats to the wrong place

**`p-floatLabel` requires the input to be a direct sibling** of the label markup.
Wrapping the control in a container — an extra `div`, a `*ngIf` host, a custom
component — silently breaks the pairing: it renders, and the label sits in the
corner.

**Check:** the control and the label are siblings in the same parent. If a wrapper
is needed, the wrapper is not allowed between them.

## The dropdown loads its entire collection

A `p-dropdown` / `p-select` bound to an array that was fetched in full does not
scale: 20 rows are instant, 20,000 freeze the tab on open.

**Fix:** page the data — the component's virtual scroll for a value list, or
`onLazyLoad` for a `p-table`. **Keep every option reachable** while doing it
(grey out or group rather than remove); see the `gates/FORMS.md` file.

## Save submits the previous value

A blur handler that writes the control's value back to state runs when the user
clicks Save — the click moves focus first, the blur fires, and the write races the
submit. The user sees a save that "did not take".

**Fix:** do not write back on blur. Write on the form's own value-changes, or read
the value at submit time. If a write-back is genuinely needed, use the control's
documented change event and, where the version supports it, its write-back
suppression.

## A virtual scroller sizes itself to nothing

A `p-autoComplete` (or any component using `p-virtualScroller`) inside a container
with no height, or inside a flex parent with `min-height: 0` removed, collapses or
grows without bound.

**Fix:** give the scroller an explicit height or item size. Its self-sizing needs a
resolved height to work from, and "auto" is not one.

## The confirm dialog asks the wrong question

A confirmation built from the config object and one built from a template do not
resolve the same way, and the config form is the one that takes the header,
labels and icons.

**Check:** the header is a question, the buttons are verbs ("Delete", not "OK"),
the destructive action is **not** the default/right-hand primary, and a destructive
button carries the danger severity. See `CODE_REVIEW.md` for the review
checklist.

## The custom control's validation is invisible

A wrapper component around a PrimeNG input that does not implement
`ControlValueAccessor` and register `NG_VALUE_ACCESSOR` is not part of the form:
`ngModel`/`formControl` writes nothing into it and its validators never run.

**Fix:** implement the contract (or extend the base the version provides), forward
the touched state, and let the control own its own `aria-required` and error
attributes — the `gates/FORMS.md` file says which attributes belong where.

## A date field cannot be typed into

A calendar that only accepts picking forces a decade of paging for a birth date and
a scroll for a distant year.

**Fix:** allow typing, parse before discarding, keep an unparseable value on screen
and report it, and give the picker a direct year/month jump. The `gates/FORMS.md` file
owns the general rule.

## The API you remember does not exist

**Verify before use, every time:**

1. the version in `package.json` / the lockfile;
2. the actual signature in `node_modules/<package>/**/*.d.ts`;
3. if it is absent, that is the answer — do not upgrade a peer dependency inside an
   unrelated change to make your memory true.

This is the single most common source of wasted time in an Angular/PrimeNG
codebase, and it is also the cheapest to avoid.
