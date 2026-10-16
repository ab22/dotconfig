# Global agent rules

Machine-global baseline for AI coding agents. Canonical source:
`~/code/dotconfig/AI/AGENTS.md`. Symlinked to `~/AGENTS.md`,
`~/.dsh/AGENTS.md`, and `~/.claude/CLAUDE.md` by `task install`.

This file is loaded for **every session, in every project**. Keep it short.

It carries only what an agent must know *before* it knows which files it will
touch: who commits, how to find the per-repo switches, and **which rule file to
read next**. Everything conditional — language, task shape, OS — lives in a rule
file reached through the router in `## Rule files` below.

## What loads, and in what order

Broad → specific. The more specific file wins where they disagree.

| # | File | Loaded | Holds |
| --- | --- | --- | --- |
| 1 | `~/.dsh/AGENTS.md` (this file) | always | universal invariants, the switch grammar, the router table |
| 2 | `<repo>/AGENTS.md` | always, committed | the repo's **team** facts: workflow preset, routing table, commands |
| 3 | `<repo>/.agents/local.md` | always, **gitignored** | this machine's overrides: rule files, personal switches |
| 4 | `~/HOST.md` → `~/.agents/hosts/<os>.md` | always | facts about this workstation: detect the OS, read its host file |
| 5 | `~/.agents/rules/**` | **on demand** | language, task, OS and gate rules — read via the router |

`.agents/local.md` may name rule files and flip switches; it may not contradict
`<repo>/AGENTS.md` on anything the team relies on. Persist a real rule by
upstreaming it into the repo's committed file or into a shared rule file — not by
leaving it in the local file where it silently differs from a teammate's.

## The switch block

Repo behaviour is declared, not assumed. Read it from the repo's committed
`AGENTS.md` frontmatter first, then let `.agents/local.md` override it.

```yaml
---
workflow: personal | work-light | work-gated    # a preset; default personal
switches:
  tdd: off | on            # tests first: failing test → red output → wait for approval
  tickets: off | on        # a plan/design doc becomes a GitHub issue before any code
  phases: off | on         # break work into phases, verify each before the next
  plan-doc: off | on       # write a phased plan document before implementing
  closing-phases: off | on # always add the closing phases (unit/integration/E2E/Postman)
  branch-flow: off | on    # branch from the dev branch (alpha), never push dev/release
  worktrees: off | on      # run side-by-side tickets in a git worktree
  review: on | off         # pre-hand-off review gate (see gates/CODE_REVIEW.md)
  validation: on | off     # the empty/null/absent boundary rules
  forms: on | off          # form, field and picker rules
rules: [rust, windows]     # rule files read at session start, on top of the router
---
```

Presets set the switches; `switches:` overrides one. Anything undeclared takes
the preset's value, and an undeclared `workflow:` means **personal**.

| Preset | tdd | tickets | phases | plan-doc | closing-phases | branch-flow | worktrees | review |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `personal` (default) | off | off | off | off | off | off | off | on |
| `work-light` | on | off | on | off | off | off | off | on |
| `work-gated` | on | on | on | on | on | on | on | on |

`validation` and `forms` are **on** in every preset; turn them off explicitly
only when the repo genuinely has no inputs or no UI.

**Every session, before the first change:** read the repo's `AGENTS.md` and, if
present, `.agents/local.md`, then state the active switches in one line, e.g.
`workflow=personal · tdd=off tickets=off phases=off review=on · rules=rust`. A
switch you did not read is a switch you cannot honour.

**`rules:`** (committed and local lists merge) names paths under
`~/.agents/rules/` without `.md`; a bare directory means its entry file —
`rust` → `rust/RUST.md`, `rust/TOKIO`, `windows`. Read each before the first
change. New repo, or changing its switches: invoke the `project-setup` skill.

Never run a gate the switches turned off. Never skip one they left on. If a
switch is wrong for the work in front of you, **say so and ask** — do not
silently override it.

## Rule files — the router

This file is the **first hop**. Rules live as plain files under
`~/.agents/rules/`; this table says which one to read. Reading one costs a file
read and nothing else — no tool, no catalog, no invocation.

| When you are about to… | Read |
| --- | --- |
| write, change or fix behaviour, with `tdd: on` | `~/.agents/rules/gates/TDD.md` |
| review a change before hand-off or a PR | `~/.agents/rules/gates/CODE_REVIEW.md` |
| file or pick up a ticket, branch, open a PR — `tickets` or `branch-flow` on | `~/.agents/rules/gates/TICKETS.md` |
| plan or phase work — `plan-doc`, `phases` or `closing-phases` on | `~/.agents/rules/gates/PLAN_PHASES.md` |
| touch `""`, `null`, `None`, `undefined` or an absent value | `~/.agents/rules/gates/VALIDATION.md` |
| build or change a form, field or picker | `~/.agents/rules/gates/FORMS.md` |
| touch **auth, authorization, new input, uploads or secrets** | `~/.agents/rules/gates/SECURITY.md` — read with `gates/CODE_REVIEW.md`, security axis first |
| run work side by side — `worktrees: on` | `~/.agents/rules/gates/WORKTREES.md` |
| write, change or review **Rust**, `Cargo.toml` or its toolchain/CI | `~/.agents/rules/rust/RUST.md` |
| work in **async Rust / Tokio** | `~/.agents/rules/rust/TOKIO.md` |
| write, change or review **Angular / PrimeNG** | `~/.agents/rules/angular/ANGULAR.md` |
| on **Windows**: call a tool missing, write a script, or debug a failed command | `~/.agents/rules/windows/WINDOWS.md` |
| the same, on **macOS** | `~/.agents/rules/macos/MACOS.md` |
| the same, on **Linux** (WSL included) | `~/.agents/rules/linux/LINUX.md` |

**These files route further.** A language file chains to its task files — the Rust
file points at `rust/API_HTTP.md`, `rust/CLI.md`, `rust/TDD.md` and
`rust/CODE_REVIEW.md`, and each of those points back at the general gate it
refines. **Follow the chain until the topic is covered**, and read the general
file a task file names before applying the specific one.

Three rules for following it:

- **Read the file before the work, not after.** A rule consulted once the code is
  written is a review, not a guide.
- **Every file states its own trigger** in a `Read this when…` line under its
  frontmatter. If that line does not match what you are doing, you took the wrong
  branch — it is not a licence to skip the file.
- **`~/.agents/rules/` is a fixed path.** It is a symlink to the `dotconfig` checkout
  and exists on every machine that has run `task install`. If it is missing, say so
  and stop rather than guessing at the rules.

An empty `rules:` means the router table is the whole story for that repo — but
read the repo's own `.agents/` before inventing any rule.

**A rule file is a floor, not a ceiling.** The repo's committed `.agents/` files
and its concrete wiring win over a shared file where they are more specific.

## Always on, whatever the switches say

- **When in doubt, never assume — ask.**
- **The user makes all commits by default.** Never run `git commit` or `git tag`
  *unless* the user asked for the whole flow in one go (commit → push → PR →
  merge). Otherwise push only after the user has reviewed, committed, and told
  you to go. Never push `alpha`, `beta`, or `main`.
- **A dirty tree or a conflict stops the work.** Report it; never `git stash`,
  `git reset --hard`, `git checkout -f`, or force-push past it.
- Keep changes minimal and focused on the request.
- Run the repo's own verification before calling anything done, and report what
  you actually ran.

## Continuous improvement

At the end of a session, if something cost time that a rule could have caught,
**suggest the improvement** — do not just note it:

1. Name what recurred and what it cost (a command retried, a trap re-derived, a
   correction the user had to make twice).
2. Route it to the narrowest lever that would have caught it:
   - true of one language → `~/.agents/rules/<lang>/`
   - true of this OS → `~/.agents/rules/<os>/`
   - true of one task shape → the task file inside that language's directory
   - true of one repo → that repo's committed `AGENTS.md`
   - true everywhere → this file
3. Say which file you would edit and what the edit is, in one or two lines.
4. Then stop. **Never edit a rule file mid-task** to record a lesson — the user
   decides, and a rule that changed under them is worse than a missing one.

Skip it when there was no friction. A suggestion that is always present is noise.

## Skills

Skills are **capabilities you invoke**; rules are files you *read*. Never add a
rule as a skill — a rule that needs an invocation silently does not load. Yours
are linked per skill from `dotconfig/AI/skills`; third-party ones come from
`AI/third-party-skills.txt` via `task skills`. Both land in `~/.agents/skills`.

- `project-setup` — set up or re-tune a repo's agent files: the switch block,
  the `rules:` list, the wiring each enabled gate needs, `.agents/local.md`.
- `authoring-agent-files` — adding or editing any agent file: a rule file, a repo
  `AGENTS.md`, `.agents/local.md`, or a skill.
- `code-review-and-quality` — the review *method* the `gates/CODE_REVIEW.md` rule
  points at.
- `test-driven-development` — the red-green-refactor method the `gates/TDD.md` rule
  points at.

## This machine

Facts about *this* workstation start at `~/HOST.md` (canonical:
`AI/host-context.md`). It does not name the OS: it says how to detect it and routes
to `~/.agents/hosts/<os>.md`. **Read that file before the first command**; the
detected OS's router row above is then live all session. **Read the host file
before concluding that a tool is missing or that a command cannot work** — a
confined shell does not inherit the host's `PATH`, so installed tools look absent;
never report one missing on that alone.
