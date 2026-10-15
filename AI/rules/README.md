# Agent context architecture

How agent context is organised across this machine: what is always in context,
what is read on demand, and where a rule belongs. **Read this before adding,
moving or editing any agent instruction file.**

This is the canonical manual referenced by the `authoring-agent-files` skill.

## The problem this solves

Instructions used to be one global file that assumed every project works the same
way: TDD, tickets, phases, and one company's `alpha` branch, applied to a dotfiles
repo and to a Metin2 server alike. Three consequences, all observed:

- **Wrong rules loaded with confidence.** A personal repo was told to write a
  failing test and file a ticket before touching a file.
- **Right rules never loaded.** `rust.md` mixed general Rust with HTTP status-code
  mapping and dependency policy in one 10.5 KB file; `angular.md` was 15.7 KB and
  applied only to UI work most sessions never touch.
- **Private detail in shared files.** Files documented as "repo-agnostic" named
  `serenity_api`, `serenity_ui`, `$HOME/code/serenity/...` and `alpha`. Those are
  one developer's layout, in a module meant to be cloned by a teammate.

## The model: a router chain

There is no index to maintain. **Each file names the next file**, and the agent
follows the chain until the topic is covered:

```
~/.dsh/AGENTS.md              always-on. Router: "working in Rust → read …/rust/RUST.md"
  └─ ~/.agents/rules/rust/RUST.md         language floor. Router again:
       ├─ …/rust/API_HTTP.md              "an HTTP service"       ┐
       ├─ …/rust/CLI.md                   "a command-line tool"   │ task files:
       ├─ …/rust/TOKIO.md                 "async / Tokio"         │ each points
       ├─ …/rust/TOOLING.md               "set up or verified"    │ back at the
       ├─ …/rust/TDD.md                   "written test-first"    │ general rule…
       └─ …/rust/CODE_REVIEW.md           "being reviewed"        ┘
            └─ ~/.agents/rules/gates/TDD.md          …the gate it refines
            └─ ~/.agents/rules/gates/CODE_REVIEW.md
```

`~/.agents/rules/` is a symlink to `AI/rules/` in this repo, created by
`task install`. The path is stable on every machine, which is what makes it safe
to hardcode in a router table and in a repo's `AGENTS.md`.

**A rule file is a plain file read with the ordinary read tool.** Not a skill, not
a tool call, not a catalogue entry. It costs exactly the tokens of its own content,
and nothing at all until it is read.

### Why not an index file

An index is a second thing to keep in sync, and it duplicates what the files
already say. Routing lives **in the parent file**, next to the context that makes
the route meaningful: the Rust file is the only place that knows both "you are in
Rust" and "here are the four Rust task files". A router is also verifiable in the
transcript — you can see which file was read, and why.

### Why not glob-scoped rules

Cursor's `globs:`, Copilot's `applyTo:` and Claude Code's `paths:` fire when the
agent **opens a matching file**. A task-shaped rule ("write an HTTP endpoint"), a
review rule, or an OS rule has no matching path, so it never loads — and the
failure is silent. The router reaches task, OS and repo conditionality, and it
works in every tool that can read a file.

### Why not a skill per rule

A skill is a **capability the model invokes**, and its catalogue entry is always in
context. Turning a rule into a skill means the rule applies only when something
chooses to invoke it, and it costs tokens in every session whether used or not.
Rules are read; capabilities are invoked. Do not mix them.

## The layers

| Layer | Scope | Mechanism | Cost |
| --- | --- | --- | --- |
| **Always-on** | every session, every project | `~/.dsh/AGENTS.md`, repo `AGENTS.md`, `.agents/local.md`, `~/HOST.md` | in every request |
| **Rule files** | one language, task, OS or gate | `~/.agents/rules/**`, read via the router | nothing until read |
| **Repo wiring** | one repo | the repo's committed `.agents/` | read by that repo's `AGENTS.md` |

The dividing line: **always-on is what an agent must know before it knows which
files it will touch** — who commits, how to find the switches, which file to read
next. Everything conditional on language, file type, task shape or OS is a rule
file.

Two measured reasons not to grow the always-on layer: instruction-following
degrades with volume even in frontier models, and every vendor truncates — Codex at
32 KiB combined, Windsurf at 12,000 chars per rule, Claude Code skipping files past
4 MiB. Keep each rule file under ~200 lines and the always-on core under ~180. When
a rule does not fit, it belongs one hop further down the chain.

## File kinds

### 1. The global baseline — `AI/AGENTS.md`

Always-on, symlinked to `~/AGENTS.md`, `~/.dsh/AGENTS.md`, `~/.claude/CLAUDE.md`.
Holds the load order, the switch grammar, **the router table**, and the invariants
that survive every switch (commit authority, dirty-tree handling,
ask-don't-assume).

**Never** put a project name, a path, a port or a gate policy here. The one thing
it legitimately hardcodes is `~/.agents/rules/`, because that path is a fixed
symlink.

### 2. The repo's committed `AGENTS.md`

The team's file, and the repo's own router. It is the only place its team-wide
workflow is declared:

- a `workflow:` preset in frontmatter (see the switch grammar);
- which extra rule files apply (`rules:`), and where its concrete wiring lives;
- the repo's commands, Definition of Done, and the modules that deliberately do
  **not** apply — recorded so nobody re-derives the decision.

It may name the repo itself. It may not name another repo the reader lacks.

### 3. The machine overlay — `<repo>/.agents/local.md`

**Gitignored, never committed.** This machine's deviation for one repo: switch
overrides, extra rule files, local paths. DSH loads it automatically (it is
registered as a `localInstructionFileCandidates` entry in the profile patch), and
the global baseline instructs every other harness to read it.

```markdown
---
switches:
  tdd: on            # this machine tests this repo even though the team does not
rules: [rust/API_HTTP, windows]
---

# Local notes

Anything here overrides the repo's committed `AGENTS.md` for this machine only.
```

Rules that hold:

- **A team dependency never lives here.** If a teammate needs it, it goes in the
  repo's committed `AGENTS.md` — the local file is invisible to them.
- **Keep it short.** It is always-on in every session in that repo.
- **DSH loads it by name; every other tool loads it because the global baseline
  says to.** That instruction is what makes it work in Claude Code, Codex and
  anything else that only reads `AGENTS.md`.

### 4. Rule files — `AI/rules/**`

Plain Markdown. Each one carries:

```markdown
---
description: One line, written as a trigger — what this file is for and when it applies.
---

> **Read this when …**

# Title
```

The blockquote is the file's own statement of its trigger. It is what a reader
uses to check they took the right branch, and what makes the file meaningful if it
is ever reached without its parent.

**Directory layout**

| Path | Holds |
| --- | --- |
| `AI/rules/gates/` | cross-cutting behaviour — one file per switch (`TDD.md`, `CODE_REVIEW.md`, `TICKETS.md`, `PLAN_PHASES.md`, `WORKTREES.md`, `VALIDATION.md`, `FORMS.md`) plus `SECURITY.md`, the switchless review axis |
| `AI/rules/<language>/` | the language floor (`RUST.md`, `ANGULAR.md`) plus that language's task files |
| `AI/rules/<os>/` | OS traps (`WINDOWS.md`, `MACOS.md`, `LINUX.md`) |

**Naming**: the file that owns a directory is uppercase and matches it
(`rust/RUST.md`, `windows/WINDOWS.md`). Task and topic files are uppercase,
underscored where needed (`API_HTTP.md`, `PLAN_PHASES.md`). A reader can tell a
directory's entry point at a glance.

**Size**: under ~200 lines. A longer one is usually two topics that should be two
files, linked from the parent's router table.

### 5. A language file's task rows

Task shape is a **row in the language file's router table**, pointing at a file in
the same directory. `rust/RUST.md` routes to `API_HTTP.md`, `CLI.md`, `TOKIO.md`,
`TOOLING.md`, `TDD.md` and `CODE_REVIEW.md` — and, for an OS × language trap, to a
section of the OS file (`windows/WINDOWS.md` § *Rust on Windows*) rather than a
copy of it.

The pattern that makes this work: **a task file names the general rule it refines,
and the reader reads that too.** `rust/TDD.md` opens by pointing at `gates/TDD.md`
and says the general file wins on any conflict — so the specific file adds only the
Rust deltas and never restates the gate.

That is the answer to "a different code review per language": there is **one**
review gate (`gates/CODE_REVIEW.md`) that owns the method and the reporting shape,
and each language has a `CODE_REVIEW.md` that owns that language's defects and
points back at the gate. The gate does not know about Rust; the Rust file does not
restate the severity labels.

### 6. This machine — `AI/host-context.md`

Symlinked to `~/HOST.md`, always-on, **OS-ordered**. Holds only what must be known
before opening a file: which OS this is, and the one-line form of each trap that
has already cost a session. The depth belongs in the OS rule files. Delete an entry
when it stops being true — a stale host fact is worse than a missing one.

### 7. Skills — `AI/skills/**`

**Capabilities the model invokes**, not rules. A skill's catalogue entry is always
in context, so every skill costs something in every session; a rule file does not.
Keep this directory for things that genuinely need an invocation: a diagram
generator, a cloud CLI, a review *method* that a rule points at, or a procedure
that writes files — `project-setup`, which writes a repo's switch block.

## The switch grammar

Declared in the repo's committed `AGENTS.md` frontmatter, overridable in
`.agents/local.md`.

```yaml
---
workflow: personal | work-light | work-gated
switches:
  tdd: off | on
  tickets: off | on
  phases: off | on
  plan-doc: off | on
  closing-phases: off | on
  branch-flow: off | on
  worktrees: off | on
  review: on | off
  validation: on | off
  forms: on | off
rules: [rust, rust/TOKIO]  # read at session start, on top of the router table
---
```

**`rules:` entries** are paths under `~/.agents/rules/` without `.md`; a bare
directory names its entry file (`rust` → `rust/RUST.md`, `windows` →
`windows/WINDOWS.md`). The committed and local lists merge. Every listed file is
read before the first change, so list only what applies to most work in the repo;
the router reaches the rest. **An OS never goes in the committed list** — it is a
fact about a machine, so it belongs in `.agents/local.md` or nowhere (`~/HOST.md`
already routes it).

**What each switch loads:**

| Switch | Rule file |
| --- | --- |
| `tdd` | `gates/TDD.md`, then `<lang>/TDD.md` |
| `review` | `gates/CODE_REVIEW.md`, then `<lang>/CODE_REVIEW.md`; `gates/SECURITY.md` at a trust boundary |
| `tickets`, `branch-flow` | `gates/TICKETS.md` |
| `phases`, `plan-doc`, `closing-phases` | `gates/PLAN_PHASES.md` |
| `worktrees` | `gates/WORKTREES.md` |
| `validation` | `gates/VALIDATION.md` |
| `forms` | `gates/FORMS.md` |

The `project-setup` skill walks a repo through choosing these and writes the
result; its catalogue lists the wiring each gate needs from the repo.

| Preset | tdd | tickets | phases | plan-doc | closing-phases | branch-flow | worktrees | review |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `personal` (default) | off | off | off | off | off | off | off | on |
| `work-light` | on | off | on | off | off | off | off | on |
| `work-gated` | on | on | on | on | on | on | on | on |

`validation` and `forms` are on in every preset.

**The default is `personal`, not `work-gated`.** A machine-global baseline cannot
know that a given repo wants another organisation's process, so it assumes nothing
and each repo declares what it needs. An undeclared `workflow:` means `personal`.

**Design rules for the switch set:**

- **A switch names a behaviour, not a tool.** `tdd` (tests first, red output, wait
  for approval) rather than `cargo-test`; `tickets` rather than `gh-plan`. The tool
  is the repo's wiring; the behaviour is the shared rule.
- **A switch must change something an agent does.** Do not add a switch for a
  preference nothing acts on.
- **Presets are named; individual switches are the escape hatch.** A repo that
  needs one exception writes one line, not a fork.
- **Off means the gate does not run at all** — not "runs but may be skipped". A gate
  that can be skipped under an "on" switch is a gate nobody trusts.

**How it is honoured:** every session starts by reading the repo's `AGENTS.md` and
`.agents/local.md` and stating the active switches in one line. That echo is the
verification — a switch the agent did not read is a switch it cannot honour, and an
undeclared gate is visible in the transcript rather than silently assumed.

## Which lever does a rule belong on?

Ask where the rule stops being true:

| Stops being true… | Lever |
| --- | --- |
| never — it holds for everyone, everywhere | `AI/AGENTS.md` (always-on) |
| in another language | `rules/<lang>/<LANG>.md` |
| when the task is a service rather than a CLI | `rules/<lang>/<TASK>.md` — and it points back at the general rule |
| on another OS | `rules/<os>/<OS>.md`, or one line in `AI/host-context.md` |
| when the gate is switched off | `rules/gates/<GATE>.md` |
| in another repo | that repo's committed `AGENTS.md` |
| on another machine, same repo | `.agents/local.md` — and ask whether it should be upstreamed |

The last row is the trap. A local overlay that quietly diverges from a teammate's
behaviour is a bug report waiting to happen; when a rule turns out to be real,
upstream it.

## Authoring a rule file

1. **Decide the layer** with the table above.
2. **Write the frontmatter `description` as a trigger**, not a summary — it is what
   a reader sees first and what a grep for the topic finds.
3. **Write the `> **Read this when …**` line.** One sentence, the condition.
4. **Add the router row in the parent file** — the global baseline, or the language
   file for a task file. **A file nothing routes to does not exist.**
5. **If it refines a general rule, point at that rule in the first paragraph** and
   say the general file wins on conflict. Do not restate it.
6. **Keep it under ~200 lines**, and under ~150 if it is always-on.

Then verify — **every routing target resolves, and no rule file is unrouted**:

```bash
# 1. every target named anywhere actually exists
grep -rhoE '~/\.agents/rules/[A-Za-z0-9_/.-]+\.md' ~/AGENTS.md ~/.agents/rules |
  sort -u | while read -r p; do [ -f "${p/#\~/$HOME}" ] || echo "DANGLING: $p"; done

# 2. every rule file is named by something (a file nothing routes to never loads)
for f in $(cd ~/.agents/rules && find . -name '*.md' ! -name README.md); do
  grep -rqF "${f#./}" ~/AGENTS.md ~/.agents/rules || echo "UNROUTED: $f"
done
```

`check-skills` validates **skills** only — it has no notion of a rule file, so both
checks above are manual. Step 4 is the one a human has to get right.

## Two named failure modes

**A rule in the wrong layer.** It is either always-on and wrong for most sessions
(the old global TDD default), or it is three hops down and the session that needed
it never got there. The question is always *where does this stop being true*, and
*how many hops from the router*.

**A private detail in a shared file.** Before adding anything to a committed file,
ask whether a teammate who has never heard of `dotconfig`, or of your other
projects, can act on it. If not, it belongs in a rule file, in `.agents/local.md`,
or in `~/HOST.md`.

## Related

- `authoring-agent-files` skill — the entry point, and the delivery checklist.
- `project-setup` skill — writes a repo's switch block, `rules:` list and gate wiring.
- `AI/AGENTS.md` — the always-on baseline and the live router table.
