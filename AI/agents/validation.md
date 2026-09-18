# Validation standards: empty string, `null`, `undefined`

Machine-wide baseline for AI coding agents. Canonical source:
`~/code/dotconfig/AI/agents/validation.md`. Referenced from `AI/AGENTS.md`.

The rule below is language-agnostic; each repo's `AGENTS.md` / `.agents/` says how
that repo implements it. Project rules take precedence.

## Why

The recurring bug class is not "missing validation", it is **two records of the
same absent value**: `""` stored where `NULL` was meant, `false` collapsed into
"not provided", `0` indistinguishable from "unset". Each boundary below has to
answer the same question the same way: *is this absent, or is this a value?*

## The four boundaries

| Boundary | The question | The rule |
| --- | --- | --- |
| Input → domain (HTTP request, CLI arg, job payload) | May the caller send nothing? | Absence means **omit the key**; `null` means **clear it**; `""`/whitespace on a required field is a **client mistake → reject** (never coerce). |
| Storage → domain (DB read) | Is `NULL` a legal state? | Map it to an explicit type (`Option<T>` / `T \| null`); never let a sentinel (`""`, `0`, `"N/A"`) stand in for "absent". |
| Form → request (UI) | Did the user clear it, or never touch it? | The **mapper** decides: untouched → key omitted; cleared → `null`. Components do not decide. |
| Response → view (UI) | Can the field be missing? | The model type must say so (`field?: T \| null`) so the compiler forces the caller to handle it. |

## Rules

1. **Absent is not empty.** `null`/`None`/`undefined` and `""` are different
   states. Never convert one into the other implicitly.
2. **Trim at the boundary, once.** Normalise whitespace on entry (request
   parsing / form mapping), not deep inside business logic.
3. **Required means non-empty after trimming.** `""` and `"   "` fail required
   validation with a client error, not a silent default.
4. **Optional strings: empty means omit, not empty-string.** A field the user
   left blank is *not sent*; a field the user cleared is sent as `null` when the
   API distinguishes the two (`PATCH` semantics).
5. **Never default a required value with `unwrap_or_default()` / `?? ''` /
   `\|\| defaultValue`.** Defaults are for genuinely optional values, and the
   chosen default is a decision, not a fallback.
6. **`||` needs a reason; `??` is the default.** On a boolean or a number, `||`
   is a bug (`false`, `0` are legitimate values). On a nullable string it is fine
   because `""` is the only falsy string. If `||` is deliberate, say so or use an
   explicit check.
7. **A helper that erases "unset" documents which it does.** If `toX(null)`
   returns `0`, the doc comment says so, and the caller that needs `null`
   preserved does not use it.
8. **Reject at the outermost boundary.** Validating in the handler/service layer
   is what makes the rule hold for every client (curl, Postman, E2E, another
   service), not just the one UI that was open at the time.

## Required test cases per boundary

Every field that can be absent needs a case for each of these; a table-driven
test is the cheapest way to cover all four.

| Case | Expected |
| --- | --- |
| `""` | rejected (required) / cleared (optional patch) |
| `"   "` / whitespace-only | same as `""` |
| key omitted / `undefined` | unchanged (patch) or default (create) |
| `null` / `None` | cleared (patch), or the documented default (create) |
| the legitimate falsy value (`0`, `false`) | preserved, not treated as absent |

## Red flags in review

- `x || undefined`, `x || 0`, `x ?? ''` on a field whose type allows `null`.
- `unwrap_or_default()` on a `String` that is a required input.
- A DB column that is `TEXT NOT NULL` with `''` as the de-facto "not set".
- A mapper that turns a cleared control into `''` on the wire.
- A test suite with no `""` / `"   "` / `null` / `undefined` case for a boundary
  that was just changed.
