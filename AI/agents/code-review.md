# Code review (shared)

How to review a change in a repo that vendors this module. The **review method**
lives in the `code-review-and-quality` skill; this file says when to invoke it,
how it relates to the evidence the repo already produces, and how to report what
you find.

Repo-specific review focus lives in the repo's own `.agents/` conventions and in
the skill's language reference — not here.

## When to invoke it

This is a **capability, not a lifecycle phase**. The `plan → implement → review →
PR` workflow keeps its single review gate, and the user owns that gate.

| # | Trigger | Required? | What invoking adds |
| --- | --- | --- | --- |
| T1 | Implementation is complete, at the **review gate**, before hand-off | Always | the findings a hand-off summarizes; the primary invocation |
| T2 | The branch is about to become a **PR** | Always | a last pass over the frozen diff, after review feedback is applied |
| T3 | Reviewing a change **you did not write** — another agent's or a human's | Always | a fresh set of axes and the multi-model pattern |
| T4 | A **bug fix** is complete | Always | review the fix *and* its regression test; a fix with no failing-first test is not done |
| T5 | A **refactor** is complete | Always | did it reduce the concepts a reader must hold, or just relocate them? |
| T6 | A **dependency** is added, removed, or upgraded | Always | changelog read, one package per change, lockfile diff reviewed, suite green before *and* after |
| T7 | The change crosses a **trust boundary** — authorization, request parsing, SQL, secrets, uploads, external data | Always; **security axis first** | the security review |
| T8 | A file grows past its healthy size, or a new conditional is bolted onto an unrelated flow | Always | a structural remedy, proposed as a *named move* |
| T9 | Docs, comments, or formatting only — no behavioural or structural change | **Skip the axes** | the review gate still applies; the five axes add nothing |

Two standing rules:

- **Scope is the branch diff against the base branch** — not the whole repo.
- **Read the tests before the implementation.** They reveal intent faster than
  the code does.

## Evidence vs. judgement — do not blur them

The repo already owns the *evidence*. The review owns the *judgement*.

| Already owned by the repo | Owned by the review |
| --- | --- |
| `.agents/verify.yaml` — the exact commands | the review axes |
| `.agents/DEFINITION_OF_DONE.md` — the checklist | severity labels |
| The definition-of-done runner (`dod`) | structural remedies |
| The hand-off report assembler (`handoff`) | the verdict |

**Consume the evidence; do not re-derive it.** Run the repo's
definition-of-done gate, then judge what it produced. A review that re-runs the
build and the tests and reports "they pass" has added nothing — and a review
never restates the Definition of Done.

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
collapse duplicate branches, replace a chain of conditionals with a typed model
or dispatcher, separate orchestration from business logic, move feature logic out
of a shared module, reuse the canonical helper, make a type boundary explicit,
delete a pass-through wrapper, or extract a helper. Prefer the remedy that
removes moving parts over one that spreads the same complexity around.

## Honesty

- **Do not rubber-stamp.** "LGTM" with no evidence of review helps nobody.
- **Do not soften a real issue.** Calling a production bug "a minor concern" is
  dishonest.
- **Quantify where you can.** "This adds a query per row, so ~50 ms per item at
  100 items" beats "this could be slow".
- **Push back on approaches with clear problems.** Deferring to the author on a
  matter of taste is fine; staying silent about a defect is not.
- **Comment on the code, not the person**, and accept a reasoned override.

## See also

- The `code-review-and-quality` skill — the five axes, structural remedies, and
  the full method.
- Its `references/code-review-rust.md` and `references/code-review-typescript.md`
  — the language-specific defects to look for.
- The repo's own `.agents/` conventions for anything stack-specific.
