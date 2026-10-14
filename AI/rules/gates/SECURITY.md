---
description: The security capability — when a change must be looked at through the security lens (auth, authorization, new input, uploads, secrets, dependencies, ship time), the threat-model-first rule, and what it deliberately does not own. Read alongside `gates/CODE_REVIEW.md` whenever a diff crosses a trust boundary.
---

> **Read this when a change touches authentication, authorization, new input, uploads, secrets or dependencies, or is about to ship.**

# Security

**Read [`CODE_REVIEW.md`](CODE_REVIEW.md) first.** It owns the review gate, the
severity labels and the reporting shape. Security is not a separate review; it is
**the security axis of that review, run first** — and this file never restates the
gate.

The **method** is the `code-review-and-quality` skill: its security axis,
`references/security-checklist.md` for the language-agnostic checklist, and
`references/security-rust.md` for the Rust/sqlx depth. This file says *when* to
apply it and what it does not own.

Repo-specific security wiring — a privilege ladder, a bucket layout, an error
mapping — belongs to that repo's own `.agents/`.

## When it applies

This is a **capability, not a lifecycle phase**. It adds no gate, no extra
verification step and no Definition of Done item. It runs from inside the review.

| # | Trigger | Required? | What it adds |
| --- | --- | --- | --- |
| S1 | **Authentication** — login, sessions, tokens, passwords, reset, invites | Always | credential handling, entropy, storage at rest, enumeration and timing |
| S2 | **Authorization** — a new or changed route, a role or privilege check, an org-scoped query | Always | the object-level check, the tenant predicate, and the negative test |
| S3 | **New input** — a new handler, query parameter, header, or deserialized field | Always | mass assignment, boundary validation, body limits |
| S4 | **Uploads or file handling** — presigned URLs, object keys, content types, finalize steps | Always | the client-asserted-parameter check and post-upload verification |
| S5 | **Secrets or configuration** — a new environment variable, a config struct, logging setup | Always | secret wrapping, `Debug` leakage, trace-level exposure |
| S6 | A **dependency** is added, removed or upgraded | Always | advisory triage by range and reachability, never by title |
| S7 | The change is about to **ship** — the PR is opening, or a deploy is going out | Always | a last pass over the frozen diff, before the findings become someone else's incident |
| S8 | Docs, comments or formatting only | **Skip** | nothing; the review gate still applies |

Two standing rules:

- **Threat model before controls.** Name the trust boundary the change crosses and
  the asset behind it. Controls chosen without that are guesses, and a guessed
  control is indistinguishable from a missing one.
- **A finding is not a fix.** This capability identifies and reports. Remediation
  is its own change, with its own failing-first test (see `TDD.md`), and is never
  smuggled into the diff under review.

## Evidence vs. judgement

The repo owns the *evidence*; this capability owns the *judgement*.

| Owned by the repo | Owned by this capability |
| --- | --- |
| its verify/test/build commands | the threat lens |
| its Definition of Done | the security review questions |
| its definition-of-done runner | whether a control is present *and sufficient* |
| its hand-off report | what to report, and how urgently |

**Consume the evidence; do not re-derive it.** Run the repo's gate, then judge what
it produced. A security pass that re-runs the build and reports "it passes" has
added nothing.

Report findings with the severity vocabulary in `CODE_REVIEW.md` — a security
finding is a review finding on the security axis, **ordered first**, not a separate
category. **Critical:** for anything that loses data or grants access; that label is
what blocks a merge.

## What this does not replace

- **The gate.** The repo's build and test commands stay the mechanical answer to
  "does it build and does it pass?".
- **Language conventions.** The skill's references are deliberately repo-agnostic;
  where a repo's own `.agents/RUST.md` differs, the repo wins.
- **A penetration test or a threat-model workshop.** This is a review capability
  applied to a diff. It narrows the window in which a defect ships; it does not
  certify a system. Never let a passing review be described as "secure".

## See also

- `CODE_REVIEW.md` — the gate this runs inside.
- The `code-review-and-quality` skill — the five axes, and its
  `references/security-checklist.md` and `references/security-rust.md`.
- The repo's own `.agents/` for anything stack-specific.
