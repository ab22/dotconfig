# Security & hardening (shared)

How to apply the security capability in a repo that vendors this module. The
**method** lives in the `code-review-and-quality` skill — its security axis, the
language-agnostic `references/security-checklist.md`, and the per-language depth
(`references/security-rust.md` today). This file says *when* to invoke it, how it
relates to the evidence the repo already produces, and what it deliberately does
not own.

Repo-specific security wiring — the concrete privilege ladder, the bucket layout,
the error mapping — lives in the repo's own `.agents/` conventions, not here.

## When to invoke it

This is a **capability, not a lifecycle phase**. The `plan → implement → review →
PR` workflow keeps its single review gate, and the user owns that gate. Invoking
this capability adds no gate, no key to `.agents/verify.yaml`, and no Definition of
Done item.

| # | Trigger | Required? | What invoking adds |
| --- | --- | --- | --- |
| S1 | A change touches **authentication** — login, sessions, tokens, passwords, password reset, invites | Always | credential handling, entropy, storage-at-rest, enumeration and timing |
| S2 | A change touches **authorization** — a new or changed route, a role or privilege check, an org-scoped query | Always | the object-level check, the tenant predicate, and the negative test |
| S3 | A change accepts **new input** — a new handler, query parameter, header, or deserialized field | Always | mass assignment, boundary validation, body limits |
| S4 | A change touches **uploads or file handling** — presigned URLs, object keys, content types, finalize steps | Always | the client-asserted-parameter check and post-upload verification |
| S5 | A change touches **secrets or configuration** — a new environment variable, a config struct, logging setup | Always | secret wrapping, `Debug` leakage, trace-level exposure |
| S6 | A change adds, removes or upgrades a **dependency** | Always | advisory triage by range and reachability, not by title |
| S7 | A change is about to be **shipped** — the PR is opening, or a deploy is going out | Always | a last pass over the frozen diff, before the capability's findings become someone else's incident |
| S8 | Docs, comments or formatting only — no behavioural, structural or configuration change | **Skip** | nothing; the lifecycle's review gate still applies |

Two standing rules:

- **Threat model before controls.** Name the trust boundary the change crosses and
  the asset behind it. Controls chosen without that are guesses.
- **A finding is not a fix.** This capability identifies and reports; remediation is
  its own change, with its own failing-first test, and is never smuggled into the
  change under review.

## Evidence vs. judgement — do not blur them

The repo owns the *evidence*. This capability owns the *judgement*. It is invoked
*from inside* the review, and it does not replace it.

| Already owned by the repo | Owned by this capability |
| --- | --- |
| `.agents/verify.yaml` — the exact commands | the threat lens |
| `.agents/DEFINITION_OF_DONE.md` — the checklist | the security review questions |
| The definition-of-done runner (`dod`) | whether a control is present and sufficient |
| The hand-off report assembler (`handoff`) | what to report, and how urgently |

**Consume the evidence; do not re-derive it.** Run the repo's gate, then judge what
it produced. A security pass that re-runs the build and reports "it passes" has
added nothing, and it never restates the Definition of Done.

Report findings, and label them, using the severity vocabulary in
`.agents/CODE_REVIEW.md` — that file owns the reporting shape, and this one does not
duplicate it. A security finding is not a separate category: it is a review finding
on the security axis, ordered first.

## What this capability does not replace

- **The gate.** `task verify` and its tooling stay the mechanical answer to "does it
  build and does it pass?".
- **The language conventions.** The skill's references are deliberately
  repo-agnostic; where a repo's own `.agents/RUST.md` differs, the repo wins.
- **A penetration test or a threat-model workshop.** This is a review capability
  applied to a diff. It narrows the window in which a defect ships; it does not
  certify a system.

## See also

- The `code-review-and-quality` skill — the five axes, including security.
- `references/security-checklist.md` — the language-agnostic checklist.
- `references/security-rust.md` — the Rust/Axum/sqlx depth.
- `.agents/CODE_REVIEW.md` — when a review is invoked, and how findings are
  reported.
- The repo's own `.agents/` conventions for anything stack-specific.
