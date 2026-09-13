# Plan docs → GitHub Issues (ticket workflow)

This module is copied into each repo as `.agents/TICKETS.md`. Tooling:
`gh-plan`, copied into each repo at `scripts/gh-plan`.

> **Where `gh-plan` lives:** the examples below write `gh-plan` for brevity. In a
> repo that vendors it, run `./scripts/gh-plan …`.

Plans and wireframes are **filed as GitHub Issues**, not kept as the source of
truth in `docs/`. A ticket's description is a short summary; the **full plan
document is embedded** at the bottom of the description inside a collapsible
`<details>` block (GitHub Issues have no file attachments, so "attach" =
"embed"). The ticket doubles as the **implementation ticket**.

Stage-by-stage gates live in `workflow.md`; branch naming in `branching.md`.

## Repos

| Short | GitHub repo | Local clone |
| --- | --- | --- |
| `api` | `ab22/serenity_api` | `/Users/abe/code/serenity_api` |
| `ui`  | `ab22/serenity_ui`  | `/Users/abe/code/serenity_ui` |

## Lifecycle

1. **Write the plan** as a Markdown doc (first line `# Title`, or a `.txt`
   banner) — e.g. in `docs/`. Declare the scope on a marker line near the top
   so the tool files in the right repo(s):

   ```markdown
   # Add inventory adjustments
   Repos: both          # api | ui | both   ← required so agents don't guess
   ```

   `Repos:` can appear anywhere in the first few lines (`> Repos: api` inside a
   blockquote also works). If it is missing, the tool defaults to **both** and
   prints a note.

   The doc must be split into **phases** with Test-Driven Design among the first
   and the closing phases (extra unit tests, integration tests, Postman/E2E
   updates) at the end — see `workflow.md`.

2. **File the ticket(s)** — run the vendored `./scripts/gh-plan` (works from
   any cwd):

   ```bash
   gh-plan new docs/my-plan.md                # → api + ui tickets
   gh-plan new docs/my-plan.md --repo api     # → api only
   gh-plan new docs/my-plan.md --dry-run      # preview, changes nothing
   ```

   Per target repo this:
   - ensures the `plan` label exists,
   - creates the issue with `plan` label, auto title (first `# ` heading /
     filename) and summary (first paragraph) — override with `--title` /
     `--summary` when the auto summary is not a good description,
   - embeds the **full document** at the bottom of the body,
   - links companion tickets across repos when it files both (`api` ↔ `ui`),
   - prints the issue URLs and the **implementation branch names**,
   - **deletes the local `docs/` file** (pass `--keep` to keep it).

3. **Implement** by picking up the ticket. First confirm the ticket exists — if
   the user asks to implement a plan that has no issue, file it first (step 2,
   `gh-plan new`) before writing any code. Then create the branch the tool
   printed (see `branching.md`), read the full plan from the ticket body
   (`gh issue view <id> -R ab22/serenity_<repo>`), and follow the repo's
   `.agents/` workflow (phases one at a time, TDD tests first) — never a local
   `docs/` copy.

4. **Review gate, then push and open the linked PR.** When the plan is
   implemented, **stop** and let the user review and commit; only once the user
   confirms and says to proceed — or as part of an explicit one-go request — do
   you push the feature branch and open the PR (do not forget the link!):

   ```bash
   gh-plan pr api 14            # run from serenity_api on the feature branch
   gh-plan pr ui 7 --draft      # body starts with "Closes #7" → auto-link
   ```

   If the work has **no issue**, do not open a PR: notify the user and wait for
   instructions.

## Picking up a ticket (implementation preconditions)

Before any implementation starts:

1. **A ticket exists.** If the plan is still only a local doc, file it first
   (`gh-plan new`) — the ticket is the source of truth and the PR needs
   something to close.
2. **`alpha` is current.** `git fetch origin && git checkout alpha && git pull
   origin alpha` — feature work always branches from `alpha` unless the user
   says otherwise.
3. **The tree is clean.** If the pull conflicts, or there are uncommitted or
   unstaged files, stop and notify the user. The user resolves it and reports
   where things stand; only then create the branch.
4. **The branch comes from the ticket** (`gh-plan branch <api|ui> <id>
   --create`), so PR↔issue linking works.

## Issue labels (lifecycle)

An open issue's label reflects its **state**, not its origin:

- `plan` — filed, not started (ready backlog). Added by `gh-plan new`.
- `in progress` — a PR is open for it. `gh-plan pr` adds this and **removes**
  `plan` when it opens the PR.
- Closed = done (issues auto-close when the PR merges into `alpha`).

Useful filters: open + `plan` = ready to pick up; open + `in progress` = being
worked; closed = shipped. Label swaps are applied by `gh-plan pr` (there is no
GitHub Action, to keep the free-plan Actions minutes for deploys) — a PR opened
manually won't auto-swap labels; use `gh-plan pr` or adjust them by hand.

## Branch naming & PR↔issue linking (summary)

Branches are **issue-driven** and use a `feat/` namespace:

```
feat/api-<issue-id>-<slug>      e.g. feat/api-14-inventory-adjustments
feat/ui-<issue-id>-<slug>       e.g. feat/ui-7-order-create-wizard
```

Branch names do **not** link a PR to an issue — the PR **body** must contain a
closing keyword (`Closes #<id>`, `Fixes #<id>`, `Resolves #<id>`) or reference
the issue. `gh-plan pr` pre-fills this. For plans that touched both repos, add
companion line too (e.g. `Companion: ab22/serenity_api#14`). Full details in
`branching.md`.

Branches promote **alpha (dev) → beta (staging) → main (production)**. Feature
branches are cut from `alpha` and PRs target `alpha` (the `gh-plan pr` default);
use `--base beta|main` for hotfixes. Release promotion (`alpha` → `beta` →
`main`) is separate from feature PRs.

## Tooling prerequisites (one-time, per machine)

```bash
brew install gh        # GitHub CLI
gh auth login          # browser; needed once — grants repo + issues scope
```

`gh-plan` is **vendored into each repo** at `scripts/gh-plan`, so no extra
checkout is required:

```bash
./scripts/gh-plan new docs/my-plan.md --repo api
```

It resolves the local clones from `$HOME/code/serenity_api` and
`$HOME/code/serenity_ui`; override with `SERENITY_API_LOCAL` /
`SERENITY_UI_LOCAL` when your layout differs.

The tool fails with a clear message if `gh` is missing or unauthenticated.

## When to create tickets

- Every **plan / design / wireframe** document (whether UI-only, API-only, or
  both) becomes a ticket — that is what makes docs discoverable.
- A plan affecting **both** repos always produces **two tickets** (one per
  repo), each with the full document embedded and a companion cross-link, so
  each repo's implementing agent has self-contained context.
- No ticket, no implementation and no PR: create the ticket first, and if a PR
  would have no issue to close, stop and ask the user.

## Updating a plan that already has a ticket

Use `gh-plan update` rather than re-creating a `docs/` file:

```bash
gh-plan update api 14 docs/my-plan.md            # refresh summary + embedded doc
gh-plan update ui 7 docs/my-plan.md --summary "…"
```

It rewrites the summary (first paragraph by default, or `--summary`) and the
embedded `<details>` document, and **preserves the companion cross-link**.
Title and labels are untouched. To iterate locally first, write the doc outside
`docs/` (e.g. `/tmp`) and pass that path.
