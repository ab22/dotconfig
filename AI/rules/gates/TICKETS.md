---
description: The ticket workflow — a plan or design document becomes a GitHub issue with the full document embedded, the ticket is the implementation source of truth, work branches from the ticket so the PR can close it, and no ticket means no PR. Includes the issue label lifecycle and the branch-naming and PR-linking rules. Use when the `tickets` or `branch-flow` switch is on and you are filing a plan, picking up a ticket, creating a feature branch, or opening a PR.
---

> **Read this when the `tickets` or `branch-flow` switch is on and you are filing a ticket, branching, or opening a PR.**

# Tickets, branches and PRs

**Every statement below is generic.** The repo's committed `AGENTS.md` supplies
the concrete wiring: which repos exist, the tool and its path, the prefix per repo,
the base branch, and the release chain. Read it first — a repo that vendors its
own ticket tool names it there, and those names win.

If `tickets: off`, do not file one. If `branch-flow: off`, do not cut a branch
from a dev branch or assume a release chain exists — the repo's default branch is
whatever it is.

## The ticket is the source of truth

Plans and wireframes are filed as **issues**, not kept as the source of truth in
`docs/`. The issue description is a short summary; the **full plan document is
embedded** at the bottom of the body inside a collapsible `<details>` block —
issues have no attachments, so *attach* means *embed*.

Consequences worth stating plainly:

- **A local `docs/` copy is a fork.** Once filed, delete it (or `--keep` it
  deliberately) — a second copy drifts and the next reader cannot tell which is
  current. The repo's tool usually deletes it for you.
- **Never implement from the local document.** Read the plan from the ticket body.
- **A plan touching two repos produces two tickets**, one per repo, each with the
  full document embedded and a companion cross-link, so each implementing agent
  has self-contained context without reaching into the other repo.

## Lifecycle

1. **Write the plan** as a Markdown doc, split into phases with Test-Driven Design
   among the first and the closing phases at the end (see `gates/PLAN_PHASES.md`).
   Declare its scope on a marker line near the top — which repo or repos — so the
   tool files it in the right place and no one has to guess.
2. **File the ticket.** Use the repo's tool, not the GitHub web UI: it ensures the
   label exists, creates the issue, embeds the document, links the companion
   ticket, and prints the implementation branch name.
3. **Implement from the ticket.** Confirm it exists first — if the user asks to
   implement a plan with no issue, file it before writing any code. Then create
   the branch the tool printed.
4. **Review gate, then push and open the linked PR** — only after the user has
   reviewed, committed, and said to go (or as part of an explicit one-go
   request). The PR body must carry the closing keyword; a branch name does not
   link anything.

## Labels

An open issue's label reflects its **state**, not its origin:

- `plan` — filed, not started (ready backlog), applied on creation.
- `in progress` — a PR is open for it; the tool adds this and removes `plan`.
- **Closed = done** — issues auto-close when the PR merges into the base branch.

Filters worth knowing: open + `plan` = ready to pick up; open + `in progress` =
being worked. If the label swap is done by the repo's tool rather than an Action,
**a PR opened by hand will not swap labels** — use the tool, or adjust them by
hand.

## Before implementing: the preconditions

1. **The ticket exists.** No ticket, no implementation.
2. **The base branch is current.** Sync it before branching, per the repo's
   `AGENTS.md`.
3. **The working tree is clean.** If the pull conflicts, or files are
   uncommitted, **stop and notify the user.** They resolve it. Never `git stash`,
   `git reset --hard`, `git checkout -f`, or force-push past it.
4. **The branch comes from the ticket**, not from your imagination, so the
   PR↔issue link works.

## Branch naming

```
<type>/<repo-prefix>-<issue-id>-<kebab-slug>
```

- **`<type>`** — `feat/` for feature work; `fix/`, `chore/` for genuinely
  unticketed work (rare — prefer filing a ticket).
- **`<repo-prefix>`** — disambiguates independent issue counters when a plan
  touches several repos. Each repo's `AGENTS.md` names its prefix.
- **`<issue-id>`** — maps 1:1 to the ticket.
- **`<kebab-slug>`** — the lowercased, dash-separated title, short enough that the
  whole branch stays readable (the tool truncates).

Keep the branch ≤ ~50 characters and let the tool create it. Never invent the name
by hand — a hand-made branch is the usual cause of a lost PR↔issue link.

## Release flow

Where the repo has a promotion chain, branches move **dev → staging →
production**, feature branches are cut from the dev branch and their PRs target
it, and release PRs are a separate, unticketed flow. Hotfixes that cannot wait
target staging or production directly. **The repo's `AGENTS.md` names the actual
branches** — never assume one.

## Linking a PR to its issue

A branch name does **not** link a PR to an issue. GitHub links them through the PR
description or the issue's Development sidebar.

- Start the PR body with a closing keyword — `Closes #<id>`, `Fixes #<id>`,
  `Resolves #<id>`. On merge, GitHub closes that issue in that repo.
- Each repo has its own issue counter, so `Closes #7` in one repo closes that
  repo's `#7` with no ambiguity.
- **Cross-repo companion:** when a plan touched two repos, add the companion line
  to each PR body (e.g. `Companion: owner/other-repo#14`).
- Use the repo's tool so this is pre-filled and never forgotten. It also validates
  you are on the expected branch and in the correct repo.
- **No issue → no PR.** Notify the user and wait for instructions rather than
  opening an orphan PR.

## Updating a plan that already has a ticket

Re-run the tool's `update` path rather than creating a second `docs/` file. It
rewrites the summary and the embedded document and preserves the companion
cross-link; title and labels are untouched. To iterate locally first, write the
draft outside `docs/` and pass that path.

## Prerequisites

`gh` must be installed and authenticated (`gh auth login`). The repo's ticket
tool is usually vendored into the repo itself (`scripts/<tool>`), so a plain clone
needs no extra checkout — check the repo's `AGENTS.md` rather than assuming either
way.
