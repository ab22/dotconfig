# Branching & PR↔issue linking

Shared convention for feature branches and how pull requests get linked to (and
close) GitHub Issues. Works for any repo in this workspace (`api` / `ui` are the
short prefixes for `serenity_api` / `serenity_ui`).

## Before you branch: sync `alpha`, check the tree

Feature work always starts from a current `alpha` (the dev branch) unless the
user specifies another base:

```bash
git fetch origin
git checkout alpha
git pull origin alpha          # alpha must carry the latest changes
```

Then create the ticket branch (see below).

**Stop and notify the user — do not work around it — when:**

- the pull reports **conflicts**,
- there are **uncommitted or unstaged** files,
- the branches have **diverged** (not a fast-forward).

The user resolves the state and tells you where things stand; only then do you
continue. Never `git stash`, `git reset --hard`, `git checkout -f`, or
force-push to get past this.

## Issue-driven feature branches

Feature work is always driven by a ticket (see `tickets.md`). Branch format:

```
feat/<repo-prefix>-<issue-id>-<kebab-slug>
```

| Repo | Prefix | Example |
| --- | --- | --- |
| serenity_api | `api` | `feat/api-14-inventory-adjustments` |
| serenity_ui | `ui`  | `feat/ui-7-order-create-wizard` |

Rules:

- `<repo-prefix>` disambiguates the two repos' **independent** issue counters
  (both have a `#1`).
- `<issue-id>` maps 1:1 to the ticket.
- `<kebab-slug>` is the lowercased, dash-separated title, ≤ 30 chars (the tool
  truncates it), so the whole branch stays ≤ ~50 chars.
- Branch from the ticket with the tool (never invent the name by hand):

  ```bash
  gh-plan branch api 14            # prints feat/api-14-inventory-adjustments
  gh-plan branch ui 7 --create     # git checkout -b feat/ui-7-… (run in that repo)
  ```

## Release flow & PR base

Branches promote **alpha (dev) → beta (staging) → main (production)**.

- Feature work is branched **from `alpha`** and its PR **targets `alpha`**
  (that is what `gh-plan branch --create` / `gh-plan pr` use by default).
- Promote with release PRs: `alpha` → `beta` → `main` (not tied to a feature
  ticket).
- Hotfixes that cannot wait for a release target `beta`/`main` directly:
  `gh-plan pr <api|ui> <n> --base beta` (or `main`).

## Non-issue work (rare)

When there is genuinely no ticket, fall back to a type namespace with a short
kebab description:

```
fix/<kebab-slug>      e.g. fix/org-picker-reset
chore/<kebab-slug>    e.g. chore/ci-node-version
```

Prefer creating a ticket over using these — issues are the source of truth, and
a PR with no issue to close cannot be opened without the user's explicit
go-ahead.

## Linking a PR to its issue

A branch name does **not** link a PR to an issue. GitHub links them through the
PR description (closing keywords) or the issue's Development sidebar.

Open the PR **only after the user has reviewed and approved the work** (see
`workflow.md`).

- **Own repo:** start the PR body with `Closes #<issue-id>` — on merge GitHub
  auto-closes that repo's issue. Each repo has its own counter, so `Closes #7`
  in `serenity_ui` closes `ui#7` with no ambiguity.
- **Cross-repo companion:** when a plan touched both repos, add the companion
  line to each PR body, e.g. `Companion: ab22/serenity_api#14`.
- Use `gh-plan pr` so this is pre-filled and never forgotten:

  ```bash
  gh-plan pr api 14            # title from the issue; body = "Closes #14" (+ companion)
  gh-plan pr ui 7 --draft
  gh-plan pr api 14 --base alpha   # target a non-default base branch
  ```

  It validates you are on the expected `feat/…` branch for the issue and that
  you run it from inside the correct repo.

- **No issue → no PR.** If the work has no ticket, notify the user and wait for
  instructions instead of opening an orphan PR.

- Supported keywords: `Closes`, `Fixes`, `Resolves` (also `… #id` multiple or
  `owner/repo#id` forms for cross-repo references).
