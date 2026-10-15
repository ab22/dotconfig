---
workflow: personal          # personal | work-light | work-gated
# switches:                 # only what differs from the preset — delete if none
#   tdd: on
#   forms: off
rules: []                   # e.g. [rust, rust/TOKIO, rust/API_HTTP] — no OS here
---

# AGENTS.md — <repo>

<One paragraph: what this repository is, who uses it, and anything an agent must
know before opening a file.>

The shared rules live under `~/.agents/rules/` and are reached through the
router in `~/AGENTS.md`; this file adds only what is true of this repo.

## Commands

| Purpose | Command |
| --- | --- |
| build | `<command>` |
| test | `<command>` |
| lint / format | `<command>` |
| **verify** — everything a change must pass | `<command>` |

## Definition of Done

- `<verify command>` green.
- <Anything else this repo requires before hand-off.>

## Gate wiring

<!-- One subsection per gate the switches leave on that needs repo facts.
     Delete the subsections for gates that are off. -->

### Tests (`tdd`)

- Unit tests live in `<path>`; integration tests in `<path>`.
- Run one test: `<command>`.

### Tickets and branches (`tickets`, `branch-flow`)

- Ticket tool: `<path>` — the repo prefix is `<prefix>`.
- Base branch: `<branch>`. Release chain: `<dev> → <staging> → <production>`.
- Never pushed by an agent: `<branches>`.

### Plans (`plan-doc`, `closing-phases`)

- Integration suite: `<command>`. E2E suite: `<command>`.
- API collection: `<path>` (update it when endpoints change).

### Worktrees (`worktrees`)

- Worktrees go in `<project-dir>/<prefix>-<ticket>`.
- Environment files to copy: `<files>`.
- Default ports: `<service>: <port>`. Shared containers: `<compose file>`.

## Repo rules

<!-- Repo-specific conventions the shared language files defer to. -->

- `.agents/<LANG>.md` — <error types, HTTP mapping, database layer, measured widths>.

## Deliberately off

<!-- Every switch turned off against its preset, with the reason. -->

- `<switch>: off` — <why>.
