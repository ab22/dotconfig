# Global agent rules

Machine-global baseline for AI coding agents. Canonical source:
`~/code/dotconfig/AI/AGENTS.md`. Symlinked to `~/AGENTS.md`,
`~/.dsh/AGENTS.md`, and `~/.claude/CLAUDE.md` by `task install`.

This file is loaded for **every session, in every project**. Project rules live
in each repo's `AGENTS.md` and `.agents/` and take precedence over this file.
Keep this file short — it is always in context.

## Working defaults

- **When in doubt, never assume — ask.**
- **Phases, one at a time.** Break work into phases and verify each before
  starting the next.
- **Tests first (TDD).** Write the failing test, run it, confirm it fails for
  the expected reason, then hand it to the user with the red output and wait for
  approval. Never write production code for a behaviour that has no failing test.
- **The user makes all commits by default.** Never run `git commit` or `git tag`
  *unless* the user explicitly asks for the whole flow in one go (commit → push →
  PR → merge). Otherwise you push only after the user has reviewed, committed,
  and told you to go — then push the feature branch and open the PR. Never push
  `alpha`, `beta`, or `main`.
- Keep changes minimal and focused on the request.

## The gated lifecycle

`plan → implement → review → PR`. Do not advance a gate on your own.

1. **Plan** — write a phased plan document. Test-Driven Design is one of the
   first phases. Always add the closing phases (more unit tests, integration
   tests, E2E/Postman updates) even when the user does not ask for them.
2. **Implement** — a ticket must exist (create it first if it does not). Branch
   from the dev branch — `alpha` where that convention applies — freshly synced
   and from a clean tree. If it conflicts, or the tree is dirty, stop and tell
   the user; do not stash, discard, or force.
3. **Review** — when implementation is done, stop. Report what changed and what
   was verified, then wait for the user.
4. **PR** — only after the user explicitly approves: then push the feature
   branch and open the PR. Never push `alpha`, `beta`, or `main`, and never open
   a PR with no ticket to close.

## Continuous improvement

- **If a session hits friction DSH could remove — repeated long commands, a
  spilled or pruned tool result, manual fan-out, a limit you worked around —
  finish the task, then suggest at most one concrete DSH capability and what it
  would have saved.** Name a tool or setting you have verified exists in this
  install (never guess a package name), route it to the right lever (agent rules
  → this file or the repo's `.agents/`; harness config → `~/.dsh/settings.yaml`
  or `~/.dsh/profiles/<p>/cordis.patch.yml`; capability gap → a note for the DSH
  checkout), and skip it if there was no friction. Never block or detour from the
  task for a suggestion.

## Before you start in a repo

1. Read the repo's `AGENTS.md`.
2. Follow the `.agents/` files it points to for the task at hand.
3. For anything touching empty strings, `null`/`None` or `undefined`, follow
   `~/code/dotconfig/AI/agents/validation.md` (the four boundaries, the required
   test cases).

## Skills

Skills are on-demand procedures; invoke the matching one before doing the work.
They live in `~/.agents/skills` (symlink → `dotconfig/AI/skills`).

- `test-driven-development` — any behaviour change, bug fix, or new logic.
- `authoring-agent-files` — adding or updating an agent file here, or vendoring
  one into a repo (symlink vs committed copy; no private paths in shared repos).
- `code-review-and-quality` — reviewing any change (your own, another agent's, or
  a human's) before hand-off or before opening the PR.
