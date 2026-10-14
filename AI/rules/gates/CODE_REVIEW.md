---
description: The pre-hand-off review gate — when to invoke `code-review-and-quality`, how to consume the evidence the repo already produces instead of re-deriving it, and how to report findings (leverage order, severity prefixes, one explicit verdict). Use when the `review` switch is on and implementation is complete, a branch is about to become a PR, or you are reviewing a diff you did not write.
---

> **Read this when the `review` switch is on and you are reviewing a change, or about to open a PR.**

# Review gate

The **method** — the five axes, the structural remedies, the language-specific
defect checklists — is the `code-review-and-quality` skill. **Load it.** This file
is the gate: when it fires, what it consumes, and how to report.

If `review: off`, this gate does not run. Say so rather than half-reviewing.

## When it fires

This is a **capability, not a lifecycle phase**. `work-gated` keeps its single
review gate and the user owns it.

| # | Trigger | Required? | What invoking adds |
| --- | --- | --- | --- |
| T1 | Implementation complete, at the gate, before hand-off | Always | the findings a hand-off summarizes |
| T2 | The branch is about to become a PR | Always | a last pass over the frozen diff |
| T3 | Reviewing a change you did not write | Always | a fresh set of axes |
| T4 | A bug fix is complete | Always | review the fix *and* its regression test |
| T5 | A refactor is complete | Always | did it reduce the concepts a reader holds? |
| T6 | A dependency is added, removed or upgraded | Always | changelog, lockfile diff, suite green before *and* after |
| T7 | The change crosses a **trust boundary** — authorization, request parsing, SQL, secrets, uploads, external data | Always; **security axis first** | read [`SECURITY.md`](SECURITY.md) and run its threat lens before the other axes |
| T8 | A file outgrows its healthy size, or a new conditional is bolted onto an unrelated flow | Always | a structural remedy, as a named move |
| T9 | Docs, comments or formatting only | **Skip the axes** | the gate still applies; the five axes add nothing |

Two standing rules:

- **Scope is the branch diff against its base** — not the whole repo.
- **Read the tests before the implementation.** They reveal intent faster than the
  code does.

## Evidence vs. judgement — do not blur them

The repo owns the *evidence*. The review owns the *judgement*.

| Owned by the repo | Owned by the review |
| --- | --- |
| its verify/test/build commands | the review axes |
| its Definition of Done | severity labels |
| its definition-of-done runner | structural remedies |
| its hand-off report | the verdict |

**Consume the evidence; do not re-derive it.** Run the repo's gate, then judge
what it produced. A review that re-runs the build and the tests and reports "they
pass" has added nothing — and a review never restates the Definition of Done.

## Reporting shape

**Order by leverage.** Correctness and security first, then structural
regressions and missed simplifications, then everything else. Do not bury a real
issue under cosmetic nits — a few high-conviction findings beat a long list. If
there is one structural problem and ten nits, the structural problem *is* the
review.

Label every finding, so the author knows what is required versus optional:

| Prefix | Meaning | Author action |
| --- | --- | --- |
| **Critical:** | blocks the merge | security hole, data loss, broken behaviour |
| *(no prefix)* | required | must be addressed before merge |
| **Optional:** / **Consider:** | suggestion | worth weighing, not required |
| **Nit:** | minor | may be ignored |
| **FYI** | informational | no action |

Close with one explicit verdict — **Approve** or **Request changes** — and say
what would have to change for a request-changes to become an approval.

When you flag a structural problem, **propose the move**, not just the problem:
collapse duplicate branches, replace a chain of conditionals with a typed model or
dispatcher, separate orchestration from business logic, move feature logic out of a
shared module, reuse the canonical helper, make a type boundary explicit, delete a
pass-through wrapper, extract a helper. Prefer the remedy that removes moving parts
over one that spreads the same complexity around.

## Honesty

- **Do not rubber-stamp.** "LGTM" with no evidence of reviewing helps nobody.
- **Do not soften a real issue.** Calling a production bug "a minor concern" is
  dishonest.
- **Quantify where you can.** "This adds a query per row, so ~50 ms per item at
  100 items" beats "this could be slow".
- **Push back on approaches with clear problems.** Deferring to the author on a
  matter of taste is fine; staying silent about a defect is not.
- **Comment on the code, not the person**, and accept a reasoned override.

## Language-specific defects

The review method is language-agnostic; the defects are not. **Read the language
file for the stack in front of you** — `rust/RUST.md` and `angular/ANGULAR.md`
each route to their own `CODE_REVIEW.md`, and the `code-review-and-quality` skill
carries further per-language references. A review of Rust with only the general
axes will miss the Rust failure modes, and that is the common case.

**State the files you read** when you report a review. "Reviewed the diff" is not
evidence; "read `gates/CODE_REVIEW.md` and `rust/CODE_REVIEW.md`" is.
