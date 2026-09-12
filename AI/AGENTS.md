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
- **The user makes all commits and pushes.** Never run `git commit`, `git push`,
  or `git tag` — no exceptions.
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
4. **PR** — only after the user explicitly approves. Never open a PR with no
   ticket to close.

## Before you start in a repo

1. Read the repo's `AGENTS.md`.
2. Follow the `.agents/` files it points to for the task at hand.

## Skills

Skills are on-demand procedures; invoke the matching one before doing the work.
They live in `~/.agents/skills` (symlink → `dotconfig/AI/skills`).

- `test-driven-development` — any behaviour change, bug fix, or new logic.
