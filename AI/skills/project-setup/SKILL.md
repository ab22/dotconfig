---
name: project-setup
description: Set up or re-tune a repository's agent files — choose the workflow preset and switch overrides that decide which gates under ~/.agents/rules/gates/ load, pick the rules list (language and task files), record the wiring each enabled gate needs (test command, ticket tool, branches, env files, ports), and write the committed AGENTS.md plus the gitignored .agents/local.md. Use when starting a new project, onboarding an existing repo to the rule system, or changing which gates a repo runs.
whenToUse: Creating a repo's AGENTS.md / .agents/ from scratch, migrating a repo onto the switch block, or turning a gate on or off for a repo.
---

# Project setup

Produces a repo whose agent behaviour is **declared, not assumed**: a committed
`AGENTS.md` whose frontmatter selects the gates, a `rules:` list for its stack,
and the concrete facts those gates need. The grammar it writes is the switch block
in `~/AGENTS.md`; the authoring rules are `~/.agents/rules/README.md` and the
`authoring-agent-files` skill. This skill is the procedure, not a second copy of
either.

The user commits. Leave every file in the working tree for review.

## 0. Preconditions

1. **It is a git repo** (`git rev-parse --show-toplevel`). If not, ask before
   `git init`.
2. **The tree is clean**, or the user knows it is not. A dirty tree stops the
   work — report it; never stash.
3. **Read what exists**: `AGENTS.md`, `CLAUDE.md`, `.agents/`, `.cursor/rules`,
   `.github/copilot-instructions.md`. Existing content is **migrated, not
   overwritten** — carry its commands, Definition of Done and conventions across,
   and show the user what moved where.

## 1. Detect, then propose

Gather the signals; do not ask what the repo already answers.

| Signal | Proposes |
| --- | --- |
| `Cargo.toml` | `rules: [rust]` — read `~/.agents/rules/rust/RUST.md` and its `TOOLING.md` |
| a `tokio` dependency | add `rust/TOKIO` |
| `axum` / `actix-web` / `hyper` / `tonic` / `poem` | add `rust/API_HTTP` |
| `clap` / `argh` / a `[[bin]]` that is a tool | add `rust/CLI` |
| `angular.json`, `@angular/core` | `rules: [angular]`; `primeng` → its file is routed from there |
| any UI at all | keep `forms: on`; with none, propose `forms: off` |
| no inputs at all (rare) | propose `validation: off` — say why out loud |
| tests exist and run | `tdd` is viable; ask whether the team wants it gated |
| a GitHub remote, issues in use, `scripts/gh-plan` or similar | `tickets` is viable |
| long-lived `alpha`/`develop`/`staging` branches | `branch-flow` is viable — read the real names |
| `.env*` files, docker compose, fixed ports | `worktrees` wiring is needed if switched on |
| integration/E2E suites, Postman/Bruno/`.http` collections | `closing-phases` wiring |

**List only what applies to most work in the repo.** `rules:` entries are read at
the start of every session; a task file needed once a month belongs to the router
chain, not the list. A language with no rule file yet gets none — note it under
*Repo rules* and offer to write one with `authoring-agent-files`.

**OS never goes in the committed list.** A teammate's OS is not yours; `~/HOST.md`
routes it, and a machine that wants it up front says so in `.agents/local.md`.

## 2. Ask — one batch

Use the harness's question tool if it has one; otherwise one message. Lead with
the recommendation the signals support.

1. **Preset** — `personal` (solo, dotfiles, experiments), `work-light` (tests
   gate the work, no ticket process), `work-gated` (issues, release chain,
   parallel tickets).
2. **Overrides** — only the switches that differ from that preset.
3. **`rules:`** — the proposed list, for confirmation.
4. **The wiring** for every gate left on — see the catalogue below. Anything the
   repo already answered, state rather than ask.

## The gate catalogue

What each switch loads, when it is worth turning on, and what the repo's
`AGENTS.md` must then supply. **A gate switched on without its wiring is a gate
the agent cannot run** — the wiring column is not optional.

| Switch | Loads | Turn on when | The repo must supply |
| --- | --- | --- | --- |
| `tdd` | `gates/TDD.md` (+ `<lang>/TDD.md`) | a behaviour change must be proven red before it is written, and someone approves the red state | the test command; where unit and integration tests live |
| `review` | `gates/CODE_REVIEW.md` (+ `<lang>/CODE_REVIEW.md`; `SECURITY.md` at trust boundaries) | always, unless the repo is throwaway | the verify command(s); the Definition of Done |
| `validation` | `gates/VALIDATION.md` | the repo takes any input — almost always | how it implements absent/`null`/`""` (`.agents/` file, if it differs) |
| `forms` | `gates/FORMS.md` | the repo has a UI | the component wiring (`.agents/ANGULAR.md` or similar) |
| `phases` | `gates/PLAN_PHASES.md` | multi-step work is verified one step at a time | a verify command per area |
| `plan-doc` | `gates/PLAN_PHASES.md` | non-trivial work needs a written plan first | where plans live (or `tickets: on`) |
| `closing-phases` | `gates/PLAN_PHASES.md` | integration, E2E or API collections exist | each suite's command; the collection path |
| `tickets` | `gates/TICKETS.md` | work is tracked as GitHub issues | the ticket tool and its path; the repo prefix; `gh` auth |
| `branch-flow` | `gates/TICKETS.md` | there is a dev → staging → production chain | the real branch names; which are never pushed |
| `worktrees` | `gates/WORKTREES.md` | tickets run side by side | project dir; repo prefixes; the env files to copy; default ports; shared containers |

`gates/SECURITY.md` has no switch: it is routed whenever a change crosses a trust
boundary, in every preset.

## 3. Write the committed `AGENTS.md`

Start from [`templates/AGENTS.template.md`](templates/AGENTS.template.md):

- **Frontmatter:** `workflow:`, then `switches:` with **only the overrides**, then
  `rules:`. Restating the preset's own values hides the one line that matters.
- **Body:** what the repo is, its commands, its Definition of Done, the wiring for
  each enabled gate, and a **Deliberately off** list — every switch turned off
  against its preset, with the reason, so nobody re-derives the decision.
- **Route, never restate.** A shared rule is named by path; its content stays in
  `~/.agents/rules/`.
- **Repo-specific conventions** (error enums, HTTP mapping, measured widths) go in
  `.agents/<LANG>.md` — the language files already defer to it — and get a line
  under *Repo rules*.
- Nothing private: no `dotconfig` path, no home directory, no other project's
  name, port or hostname. A teammate who has never seen this machine must be able
  to act on every line.

If the team uses a harness that reads only `CLAUDE.md`, add a one-line `CLAUDE.md`
containing `@AGENTS.md`. Never a second copy of the content.

## 4. The machine overlay — only if needed

`.agents/local.md` (from [`templates/local.template.md`](templates/local.template.md)) holds this
machine's deviations: an extra rule file such as `windows`, a switch this machine
runs differently, a local path. Skip it when there is none. It must be ignored:
`git check-ignore -v .agents/local.md` names the global rule, or the repo needs one.

## 5. Verify — expect no output from each check

```bash
# every rules: entry resolves (bare dir → its entry file; else <entry>.md)
for r in $(sed -n 's/^rules: *\[\(.*\)\]/\1/p' AGENTS.md .agents/local.md 2>/dev/null | tr ',' ' '); do
  f="$HOME/.agents/rules/$r"
  if [ -d "$f" ]; then f="$f/$(basename "$r" | tr '[:lower:]' '[:upper:]').md"; else f="$f.md"; fi
  [ -f "$f" ] || echo "MISSING rule: $r"
done
# the overlay is ignored, and nothing private leaked
[ -e .agents/local.md ] && { git check-ignore -q .agents/local.md || echo "NOT IGNORED: .agents/local.md"; }
grep -rnE 'dotconfig|/Users/|/home/[a-z]|C:\\Users' AGENTS.md .agents 2>/dev/null | grep -v '^.agents/local.md'
```

Then **echo the switch line** exactly as a session would —
`workflow=work-light · tdd=on tickets=off phases=on review=on · rules=rust,rust/TOKIO`
— and confirm it with the user. That line is the contract.

## Re-tuning an existing repo

Same steps, but diff: show the old and new switch line, add the wiring for any
gate turned on, and move a gate turned off into *Deliberately off* with its reason.
