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
| `skills/` | **Capabilities** the model invokes (not rules). `~/.agents/skills` links the whole tree; `~/.claude/skills/<name>` links one skill at a time. |
| `host-context.md` | This machine's facts, OS-ordered, always-on. Symlinked to `~/HOST.md`. |
| `agents/` | **Retired.** The old vendored modules, kept for reference while repos migrate. |

**`~/.claude/skills` stays a real directory.** Claude Code's plugin and
marketplace installers, and third-party installers such as `npx impeccable
install`, create skill folders inside it — a directory symlink to `AI/skills`
would make every one of those writes land inside this public repo. `link.sh`
therefore links one skill at a time and leaves the rest of the directory to the
tools that own it.

### Third-party skills

Do not vendor these into `AI/skills/`. Each ships its own installer and its own
copy per harness:

| Skill | DSH | Claude Code |
| --- | --- | --- |
| `impeccable` | `bash ~/code/agent-toolkit/scripts/install-impeccable.sh` → `~/.dsh/skills/impeccable` | `/plugin marketplace add pbakaus/impeccable`, then install from `/plugin` |

`--check` reports the DSH copy's state without touching the network.

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
| `WORKTREES.md` | running several pieces of work side by side |
| `rust/RUST.md` | writing, changing or reviewing Rust |
| `rust/TOKIO.md` | async Rust — Tokio, blocking, channels, timeouts, shutdown |
| `angular/ANGULAR.md` | writing, changing or reviewing Angular / PrimeNG |
| `windows/WINDOWS.md` | a Windows-specific trap |
| `macos/MACOS.md` | a macOS-specific trap |
| `linux/LINUX.md` | a Linux-specific trap |

Each language file routes further: `rust/` holds `API_HTTP.md`, `CLI.md`,
`TOKIO.md`, `TDD.md` and `CODE_REVIEW.md`; `angular/` holds `PRIMENG.md`, `TDD.md`
and `CODE_REVIEW.md`.

The per-repo switch block — `workflow: personal | work-light | work-gated` plus
individual overrides and a `rules:` list — is documented in `AGENTS.md` and
`rules/README.md`.

## Installing

```bash
cd ~/code/dotconfig && task install
```

That links the global agent files, the rule files, the capabilities, the shell
profiles (including `~/.local/bin` on `$PATH`), the editor configs and
`~/.gitignore` — then runs the `agent-toolkit` installer when that repo is present.
`link.sh` reports how many links it created, found already in place, and
**skipped**; check the skip count.

## Tools

`gh-plan`, `plan`, `preflight`, `handoff`, `dod` and `check-skills` ship in
`agent-toolkit`:

```bash
cd ~/code/agent-toolkit && task install     # → ~/.local/bin
task verify-install                         # after a shell/harness restart
```

`gh-plan` is additionally vendored into each project repo at `scripts/gh-plan`, so
a plain clone needs no extra checkout.
