# Plan docs → GitHub Issues (ticket workflow)

Canonical shared module. Adopted by `serenity_api` and `serenity_ui` (each as
`.agents/TICKETS.md`, a relative symlink to this file). Tooling: `gh-plan`
(canonical in `ab22/dotconfig` → `AI/bin/gh-plan`, on `$PATH`).

Plans and wireframes are **filed as GitHub Issues**, not kept as the source of
truth in `docs/`. A ticket's description is a short summary; the **full plan
document is embedded** at the bottom of the description inside a collapsible
`<details>` block (GitHub Issues have no file attachments, so "attach" =
"embed"). The ticket doubles as the **implementation ticket**.

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

2. **File the ticket(s)** — `gh-plan` is on `$PATH` (repo-agnostic), so it
   works from any repo and any cwd:

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

3. **Implement** by picking up the ticket. Start from the branch the tool
   printed (see `branching.md`), read the full plan from the ticket body
   (`gh issue view <id> -R ab22/serenity_<repo>`), and follow the repo's
   `.agents/` + TDD conventions.

4. **Open the linked PR** (do not forget the link!):

   ```bash
   gh-plan pr api 14            # run from serenity_api on the feature branch
   gh-plan pr ui 7 --draft      # body starts with "Closes #7" → auto-link
   ```

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

`gh-plan` needs `ab22/dotconfig` cloned at `~/code/dotconfig` (its `AI/bin` is
on `$PATH` via `root/<os>/.zshrc`). If it is not on `$PATH`, run
`~/code/dotconfig/AI/bin/gh-plan` directly.

The tool fails with a clear message if `gh` is missing or unauthenticated.

## When to create tickets

- Every **plan / design / wireframe** document (whether UI-only, API-only, or
  both) becomes a ticket — that is what makes docs discoverable.
- A plan affecting **both** repos always produces **two tickets** (one per
  repo), each with the full document embedded and a companion cross-link, so
  each repo's implementing agent has self-contained context.

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
