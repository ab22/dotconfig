# AI (agent configuration)

The agent context system for this machine: one small always-on baseline that acts
as a **router**, a tree of rule files it points at, and the per-repo overlay that
makes a repository's behaviour declared rather than assumed.

**Read [`rules/README.md`](rules/README.md) first.** It is the canonical manual —
the router model, every file kind, the switch grammar, and where a rule belongs.

**CLI tools do not live here.** They are a separate repository (`agent-toolkit`),
installed as regular user binaries into `~/.local/bin`; see its `README.md`.

## How context loads

```
ALWAYS-ON  (in every request)              ON DEMAND  (a file read, nothing else)
  ~/.dsh/AGENTS.md      universal rules      ~/.agents/rules/gates/*.md      behaviour gates
  <repo>/AGENTS.md      team facts + router  ~/.agents/rules/rust/RUST.md    language floor
  <repo>/.agents/local.md  this machine      ~/.agents/rules/rust/API_HTTP.md, CLI.md,
  ~/HOST.md             this machine's OS                                  TDD.md, CODE_REVIEW.md
                                             ~/.agents/rules/angular/…      language + tasks
                                             ~/.agents/rules/{windows,macos,linux}/
```

The always-on file names the first hop; **each rule file names the next**. To reach
a language's code-review rules: `~/.agents/rules/rust/RUST.md` →
`rust/CODE_REVIEW.md` → the general `gates/CODE_REVIEW.md` it refines.

## Layout

| Path | Purpose |
| --- | --- |
| `AGENTS.md` | The machine-global baseline — always-on. Symlinked to `~/AGENTS.md`, `~/.dsh/AGENTS.md`, `~/.claude/CLAUDE.md`. |
| `rules/README.md` | **The canonical authoring manual.** |
| `rules/` | The rule files. Symlinked to `~/.agents/rules`; read via the router. |
| `skills/` | **First-party capabilities** the model invokes (not rules) — skills you wrote or changed. Linked one skill at a time into `~/.agents/skills/<name>` and `~/.claude/skills/<name>`. |
| `third-party-skills.txt` | **Third-party skills**, by source — installed on every machine by `task skills`, never vendored. |
| `host-context.md` | This machine's facts, OS-ordered, always-on. Symlinked to `~/HOST.md`. |

**Both skill roots stay real directories.** The `skills` CLI, Claude Code's
plugin and marketplace installers, and installers such as `npx impeccable
install` create skill folders inside them — a directory symlink to `AI/skills`
would make every one of those writes land inside this public repo. `link.sh`
therefore links one skill at a time and leaves the rest of each directory to the
tools that own it (it also turns an old whole-directory `~/.agents/skills` link
back into a directory).

### Third-party skills

A skill whose upstream owns the content is **listed, not copied**: one line in
`third-party-skills.txt` (`<source> <skill>`). `task install` runs `task skills`,
which installs each missing one with the `skills` CLI (`npx skills add -g`) into
`~/.agents/skills` (DSH, Codex) and `~/.claude/skills` (Claude Code) — so every
machine gets the same set, and `task skills:update` pulls the latest upstream.
It needs Node.js; without it the rest of `task install` still completes.

| Skill | Source | Installed by |
| --- | --- | --- |
| `archify` | `tt-a1i/archify` | `task skills` |
| `find-skills` | `vercel-labs/skills` | `task skills` |
| `impeccable` | `pbakaus/impeccable` | DSH: `bash ~/code/agent-toolkit/scripts/install-impeccable.sh` → `~/.dsh/skills/impeccable`; Claude Code: `/plugin marketplace add pbakaus/impeccable` |

**Changing a third-party skill makes it yours:** copy it into `AI/skills/`, take
its line out of the list, and say at the top of its `SKILL.md` where it came from
— as `code-review-and-quality` and `test-driven-development` do.

### The rule files

| Read | When |
| --- | --- |
| `gates/TDD.md` | writing or changing behaviour |
| `gates/CODE_REVIEW.md` | reviewing a change before hand-off or a PR |
| `gates/SECURITY.md` | touching auth, authorization, new input, uploads or secrets |
| `gates/TICKETS.md` | filing or picking up a ticket, branching, opening a PR |
| `gates/PLAN_PHASES.md` | writing a phased plan document |
| `gates/VALIDATION.md` | touching `""`, `null`, `None`, `undefined` or an absent value |
| `gates/FORMS.md` | building or changing a form, field or picker |
| `gates/WORKTREES.md` | running several pieces of work side by side |
| `rust/RUST.md` | writing, changing or reviewing Rust |
| `rust/TOKIO.md` | async Rust — Tokio, blocking, channels, timeouts, shutdown |
| `angular/ANGULAR.md` | writing, changing or reviewing Angular / PrimeNG |
| `windows/WINDOWS.md` | on Windows: a tool looks missing, a script is written, a command or build fails |
| `macos/MACOS.md` | the same, on macOS |
| `linux/LINUX.md` | the same, on Linux or WSL |

Each language file routes further: `rust/` holds `API_HTTP.md`, `CLI.md`,
`TOKIO.md`, `TOOLING.md`, `TDD.md` and `CODE_REVIEW.md`; `angular/` holds `PRIMENG.md`, `TDD.md`
and `CODE_REVIEW.md`.

The per-repo switch block — `workflow: personal | work-light | work-gated` plus
individual overrides and a `rules:` list — is documented in `AGENTS.md` and
`rules/README.md`. **To set one up for a new or existing repo, invoke the
`project-setup` skill**: it detects the stack, asks for the preset and overrides,
and writes the committed `AGENTS.md` with the wiring each enabled gate needs.

## Installing

```bash
cd ~/code/dotconfig && task install
```

That links the global agent files, the rule files, the capabilities, the shell
profiles (including `~/.local/bin` on `$PATH`), the editor configs and
`~/.gitignore` — then runs the `agent-toolkit` installer when that repo is present,
and finally `task skills` for the third-party skills. `link.sh` reports how many
links it created, found already in place, skipped and pruned; check the skip count.

## Tools

`gh-plan`, `plan`, `preflight`, `handoff`, `dod` and `check-skills` ship in
`agent-toolkit`:

```bash
cd ~/code/agent-toolkit && task install     # → ~/.local/bin
task verify-install                         # after a shell/harness restart
```

`gh-plan` is additionally vendored into each project repo at `scripts/gh-plan`, so
a plain clone needs no extra checkout.
