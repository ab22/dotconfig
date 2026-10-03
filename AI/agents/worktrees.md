# Worktrees

How to run several tickets side by side without them fighting over ports, env
files, or each other's working tree.

A `git worktree` is a second working directory for one repository. Checkouts,
branches and `.git` are shared; the files on disk and the checked-out branch are
not. That is what lets you leave a half-finished feature alone and start the next
ticket without stashing — and it is the reason the steps below exist.

## 1. Where it goes

Create it **next to** the project's main checkouts, at the same level:

```
~/code/<project>/<api|ui>-<ticket>
```

The directory name is `{project-name}-{ticket-name}[-{short-description}]`:

- `{project-name}` — the repo you are branching from: `api` or `ui`.
- `{ticket-name}` — the issue number.
- `{short-description}` — optional; add it when you will have several worktrees
  open and the number alone is not enough to recognise one.

So `~/code/<project>/api-72` or `~/code/<project>/api-72-org-language` — never
nested inside another worktree, and never named after the branch.

## 2. Create it

Let the ticket name the branch; do not invent one.

```bash
cd ~/code/<project>/api
git fetch origin
./scripts/gh-plan branch api <id> --create
git worktree add ../api-<id> feat/api-<id>-<slug>
```

`git worktree add` refuses a directory that already exists, so a typo cannot
silently clobber a checkout. `git worktree list` shows them all.

## 3. Copy the environment in

The env files are gitignored, so a fresh worktree does not have them, and the
app will not start without them. Copy every one the repo's `AGENTS.md` lists
under "Environment files" — typically the API `.envrc`, the API `e2e/.env`, and
the UI `.env` (Terraform only). Never commit them.

## 4. Move the ports

This is the point of the exercise: the main checkout keeps the project's default
ports and each worktree takes its own, so two of them can run and be tested at
the same time.

- **API** — change `PORT` (default `8080`) in that worktree's `.envrc`.
- **UI** — serve on another port (`ng serve --port <n>`, default `4200`) **and**
  point the development `apiUrl` at that worktree's API port.
- Pick a pattern you can remember (`default + worktree number` is enough) and
  check the port is free first: `lsof -nP -iTCP:<port> -sTCP:LISTEN`.

If the UI reads its API URL from a **committed** environment file, that edit
stays uncommitted in the worktree on purpose. Do not commit it.

## 5. Share the containers, mind the migrations

Docker dependencies (database, object storage, tracing) are **shared**. A second
stack per worktree wastes memory and hides which database a test really ran
against; reuse the running containers.

The consequence is the part that bites: every worktree points at the **same
database**, so a migration applied from one branch is still applied after you
switch to another.

- Local startup tolerates exactly that (`migration … was previously applied but
  is missing in the resolved migrations`) — and **only** locally. A deployed
  stage still fails loudly, because there it means the deployed schema and the
  deployed code disagree.
- So think before you migrate. Prefer additive, backwards-compatible migrations,
  and do not revert one while other worktrees are pointed at the same database:
  the revert is global and takes their schema with it.
- If you would rather the drift were impossible, give the worktree its own
  *database* — not its own container: point `POSTGRES_DB` in that `.envrc` at a
  per-worktree name and run the migrate task once. Optional.

## 6. Clean up once the PR is merged

A worktree is not an ordinary directory. Deleting it by hand leaves a
registered-but-missing checkout that `git worktree list` keeps reporting.

1. **Sync the base branch** in the main checkout:
   `git fetch origin && git checkout <dev> && git pull origin <dev>`.
2. **Close the ticket's labels**, if the repo uses that lifecycle:
   `./scripts/gh-plan close api <id>`.
3. **Stop everything running in the worktree** — dev server, watcher, E2E run.
   A process still holding the port or the directory is the usual reason the next
   step complains.
4. **Remove the worktree:** `git worktree remove ../api-<id>`. If it refuses
   because the worktree is dirty, that check is doing its job — look at
   `git -C ../api-<id> status` and decide whether the work is worth keeping.
   `--force` discards it; use it deliberately, never because the first attempt
   failed.
5. **Delete the branch** (merged, so `-d` must succeed):
   `git branch -d feat/api-<id>-<slug>` then `git worktree prune`.
6. **Drop the worktree's database** if you made one in step 5, together with its
   integration sibling. Leave the shared database alone — migrations another
   branch applied are still in use.
7. **Confirm:** `git worktree list` shows only the main checkouts.
