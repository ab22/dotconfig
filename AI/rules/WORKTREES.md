---
description: Running several tickets side by side in a git worktree — where the worktree goes and how it is named, copying the gitignored env files in, moving the ports so two stacks can run at once, the shared-database migration caution, and cleanup once the PR has merged. Use when the `worktrees` switch is on and two pieces of work have to run at the same time.
---

> **Read this when the `worktrees` switch is on and two pieces of work have to run at the same time.**

# Worktrees

A `git worktree` is a second working directory for one repository. Checkouts,
branches and `.git` are shared; the files on disk and the checked-out branch are
not. That is what lets you leave a half-finished feature alone and start the next
ticket without stashing — and it is the reason the steps below exist.

**The repo's `AGENTS.md` supplies the concrete names**: its project directory, its
repo prefixes, which env files exist, its default ports, and whether it shares
containers. Read that first; this file is the procedure.

If `worktrees: off`, do not reach for one — the switch exists because a repo may
prefer a plain branch switch.

## 1. Where it goes

Create it **next to** the project's main checkouts, at the same level:

```
<project-dir>/<prefix>-<ticket>
```

The directory name is `{prefix}-{ticket-name}[-{short-description}]`:

- `{prefix}` — the repo you are branching from;
- `{ticket-name}` — the issue number;
- `{short-description}` — optional, when several worktrees will be open and the
  number alone is not enough to recognise one.

**Never** nest a worktree inside another worktree, and never name it after the
branch.

## 2. Create it

Let the ticket name the branch; do not invent one.

```bash
cd <project-dir>/<prefix>
git fetch origin
<the repo's ticket tool> branch <prefix> <id> --create
git worktree add ../<prefix>-<id> <the branch the tool printed>
```

`git worktree add` refuses a directory that already exists, so a typo cannot
silently clobber a checkout. `git worktree list` shows them all.

## 3. Copy the environment in

**The env files are gitignored**, so a fresh worktree does not have them and the app
will not start without them. Copy every one the repo's `AGENTS.md` lists under an
"Environment files" heading — typically a shell env file, an E2E env file, and any
Terraform or deploy-only file. **Never commit them.**

If the repo has no such list, that is a gap worth adding there: the next worktree
pays the same tax.

## 4. Move the ports

This is the point of the exercise: the main checkout keeps the project's default
ports and each worktree takes its own, so two of them can run and be tested at the
same time.

- Change the port in that worktree's env file, and wherever the UI's API URL is
  configured.
- Pick a pattern you can remember (default + worktree number is enough) and **check
  the port is free first**:
  `lsof -nP -iTCP:<port> -sTCP:LISTEN` (Linux/macOS) —
  `Get-NetTCPConnection -LocalPort <port>` (Windows).
- If the UI reads its API URL from a **committed** environment file, that edit stays
  **uncommitted** in the worktree on purpose. Do not commit it.

## 5. Share the containers, mind the migrations

Docker dependencies (database, object storage, tracing) are **shared**. A second
stack per worktree wastes memory and hides which database a test really ran
against; reuse the running containers.

**The consequence is the part that bites:** every worktree points at the **same
database**, so a migration applied from one branch is still applied after you switch
to another.

- Local startup usually tolerates exactly that (`migration … was previously applied
  but is missing in the resolved migrations`) — and **only** locally. A deployed
  stage still fails loudly, because there it means the deployed schema and the
  deployed code disagree.
- **Think before you migrate.** Prefer additive, backwards-compatible migrations.
- **Do not revert a migration while other worktrees point at the same database** —
  the revert is global and takes their schema with it.
- If you would rather the drift were impossible, give the worktree its own
  *database* rather than its own container: point the database-name variable at a
  per-worktree name and run the migrate task once. Optional.

## 6. Clean up once the PR has merged

A worktree is not an ordinary directory. **Deleting it by hand leaves a
registered-but-missing checkout** that `git worktree list` keeps reporting.

1. **Sync the base branch** in the main checkout.
2. **Close the ticket's labels**, if the repo uses that lifecycle.
3. **Stop everything running in the worktree** — dev server, watcher, E2E run. A
   process still holding the port or the directory is the usual reason the next step
   complains.
4. **Remove it:** `git worktree remove ../<prefix>-<id>`. If it refuses because the
   worktree is dirty, **that check is doing its job** — look at `git -C
   ../<prefix>-<id> status` and decide whether the work is worth keeping. `--force`
   discards it; use it deliberately, never because the first attempt failed.
5. **Delete the local branch** (merged, so `-d` must succeed), then
   `git worktree prune`. The **remote** branch usually needs no step: with GitHub's
   *"Automatically delete head branches"* setting on, merging the PR removes it —
   turn that setting on where it is off, because it cannot be forgotten. `-d`
   refusing is then a useful check that the PR really landed.
6. **Drop the worktree's database** if you made one in step 5, together with its
   integration sibling. Leave the shared database alone — migrations another branch
   applied are still in use.
7. **Confirm:** `git worktree list` shows only the main checkouts.
