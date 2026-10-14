---
name: authoring-agent-files
description: Rules for authoring agent instruction files — the always-on global baseline that acts as a router, the rule files it points at (gates, language floors, task files, OS traps), a per-repo AGENTS.md, the gitignored .agents/local.md overlay, and skills as something separate. Covers the delivery split, the router-row requirement, and keeping shared repos free of private context. Use when adding or editing any agent file or deciding where a rule belongs.
whenToUse: Creating, editing or reviewing an agent instruction file (AGENTS.md, a rule file under AI/rules/, .agents/local.md, a DSH skill), or deciding which layer a rule belongs on.
---

# Authoring agent files

> **Personal-only.** This skill describes `dotconfig`'s layout and one machine.
> It is **never vendored** into a repo.

## The canonical documentation

The full authoring manual — the router model, every file kind, the switch grammar,
naming, and the drift and leak checks — is `AI/rules/README.md` in the `dotconfig`
checkout. **Read it before writing a rule file.** It is kept current in the repo;
this skill is the entry point that routes you there and states the rules that must
not be broken.

Do not copy the manual into a repo. Do not copy it into this skill.

## Rules vs skills — do not mix them

| | Rule | Skill |
| --- | --- | --- |
| What it is | context the agent **reads** | a capability the model **invokes** |
| Lives in | `AI/rules/**` → `~/.agents/rules/**` | `AI/skills/**` → `~/.agents/skills/**` |
| Costs when unused | **nothing** | its catalogue entry, in every session |
| Reached by | a router row in the parent file | a tool invocation |
| Example | `rust/CODE_REVIEW.md` | `code-review-and-quality` |

**A rule filed as a skill is a rule that silently does not load** — nothing invokes
it, and it still costs tokens forever. If in doubt, it is a rule.

## The one rule

**`dotconfig` is private. The repos are shared.**

A teammate who has never heard of `dotconfig` must be able to `git clone` a shared
repo and have every agent file in it work.

## Three delivery mechanisms — never mixed

| Mechanism | Allowed for | Never for |
| --- | --- | --- |
| **Symlink**, created by dotconfig's `task install` | paths under `$HOME` that are yours alone: `~/AGENTS.md`, `~/.dsh/AGENTS.md`, `~/.claude/CLAUDE.md`, `~/.agents/rules` → `AI/rules`, `~/.agents/skills` → `AI/skills`, `~/.claude/skills/<name>` → `AI/skills/<name>` **(one link per skill)**, `~/HOST.md` → `AI/host-context.md`, `~/.gitignore` → `root/.gitignore`, the editor configs | **anything inside a shared repo**; **a tool's own skill root as a whole directory** (see below) |
| **Committed copy** | every agent file inside a shared repo: its `AGENTS.md` and its own `.agents/*` | — |
| **Gitignored, local only** | `<repo>/.agents/local.md` — this machine's switches and extra rule files | anywhere a teammate needs it |

### Never symlink a harness's skill root as a whole directory

`~/.claude/skills` is a **real directory** on purpose. Claude Code's plugin and
marketplace installers — and third-party installers such as `npx impeccable
install` — create skill folders *inside* it. A directory symlink to `AI/skills`
means every one of those writes lands **inside this public repo**.

`link.sh` therefore links **one skill at a time** into `~/.claude/skills/<name>`,
leaving room for the tools that own their own folders there. `~/.agents/skills`
*is* a directory link, because nothing writes into it: DSH only reads it.

The general rule: link a tree you own and only read from; link individual entries
into a tree another tool writes to.

A symlink from a shared repo into `~/code/dotconfig/...` is **broken for every
other developer and for CI**. The clone succeeds and the files dangle.

Equivalently: **no file committed to a shared repo may contain a `~/code/dotconfig`
path**, and none may name a private project, path or port.

## Where does the content belong?

| The content is… | Home | Delivery |
| --- | --- | --- |
| True in every session, every project, every OS | `AI/AGENTS.md` | symlink only |
| True of one language, task shape, OS or gate | `AI/rules/**` | symlink `~/.agents/rules`; read via the router |
| The router model, file kinds, conventions | `AI/rules/README.md` | canonical doc; linked, never copied |
| A capability the model must invoke | `AI/skills/**` | symlink `~/.agents/skills` (whole tree) **and** `~/.claude/skills/<name>` (per skill) |
| A capability a third party ships and updates | **nothing here** | install it with its own installer into the harness that owns it |
| This machine's facts | `AI/host-context.md` | symlink `~/HOST.md`, always-on |
| The repo's team workflow, commands, Definition of Done | the repo's committed `AGENTS.md` | lives there; never comes from dotconfig |
| This machine's deviation for one repo | `<repo>/.agents/local.md` | gitignored; local only |
| Personal-only — mentions dotconfig or this machine | anywhere in `AI/` | never vendored; say so at the top of the file |

## Rule-file anatomy

```markdown
---
description: One line, written as a trigger — what this file is for and when it applies.
---

> **Read this when …**

# Title
```

- **The `description` is a trigger, not a summary.** "Rust conventions" routes
  nothing; "Read this when working in Rust, then route to the API/CLI/TDD/review
  files" does.
- **The `> **Read this when …**` line is required.** It is how a reader checks they
  took the right branch, and what makes the file meaningful if it is reached without
  its parent.
- **Under ~200 lines**; under ~150 if always-on.
- **Uppercase filenames.** The directory owner matches its directory
  (`rust/RUST.md`, `windows/WINDOWS.md`); topics are uppercase and underscored
  (`API_HTTP.md`, `PLAN_PHASES.md`).
- **No `name:` or `whenToUse:`** — those are skill frontmatter keys, not rule-file
  ones. A rule file carries `description` only.
- **Relative links stay inside the file's own directory** (`API_HTTP.md`, not
  `rust/API_HTTP.md` from inside `rust/`). A link out of the directory breaks the
  moment the file is read from another path.

## The router row is part of the change

**A rule file that nothing routes to does not load.** Adding a file means adding the
row that reaches it — in `AI/AGENTS.md` for a new top-level topic, or in the
language file for one of its task files. There is no automated gate for this:
`check-skills` validates *skills*, not rule files.

If the new file refines a general rule, **point at that rule in the first paragraph
and say the general file wins on conflict.** Do not restate it — that is how the
same rule ends up in three places with three slightly different meanings.

## Creating or updating — checklist

1. **Pick the layer** — `AI/rules/README.md` has the "which lever" table.
2. **Edit the canonical file in dotconfig.** Nothing is vendored any more; a shared
   repo holds only its own `AGENTS.md` and `.agents/`.
3. **Add the router row**, in the same change.
4. **Prove every routing target resolves** — expect no output:
   ```bash
   grep -rhoE '~/\.agents/rules/[A-Za-z0-9_/.-]+\.md' ~/AGENTS.md ~/.agents/rules |
     sort -u | while read -r p; do [ -f "${p/#\~/$HOME}" ] || echo "DANGLING: $p"; done
   ```
5. **Prove no rule file is unrouted** — expect no output:
   ```bash
   for f in $(cd ~/.agents/rules && find . -name '*.md' ! -name README.md); do
     grep -rqF "${f#./}" ~/AGENTS.md ~/.agents/rules || echo "UNROUTED: $f"
   done
   ```
6. **Prove no private context leaked** — expect no output, per shared repo:
   ```bash
   grep -rn "dotconfig\|code/serenity\|/Users/" <repo>/AGENTS.md <repo>/.agents
   ```
7. **Prove the overlay is ignored** — expect `.agents/local.md`, per repo:
   ```bash
   git -C <repo> check-ignore -v .agents/local.md
   ```
8. **If you touched a skill** (not a rule), validate it:
   ```bash
   check-skills ~/code/dotconfig/AI/skills
   ```
9. **If a script rewrote the files, prove the bytes survived** — see below.

## Never rewrite these files with PowerShell text cmdlets

This has already cost a session. On Windows PowerShell 5.1, `Get-Content` followed
by `Set-Content` silently **double-encodes** UTF-8 punctuation. One character
becomes three:

| Original | After the round trip |
| --- | --- |
| the em dash `U+2014` | `U+00E2` `U+20AC` `U+201D` |
| the ellipsis `U+2026` | `U+00E2` `U+20AC` `U+00A6` |
| the right arrow `U+2192` | `U+00E2` `U+2020` `U+2019` |

The bytes are read as UTF-8, reinterpreted as cp1252, and written back as UTF-8.
`Set-Content -Encoding UTF8` also **adds a BOM**, which is unwanted in frontmatter.

Nothing warns you: the files still render, the frontmatter still parses, and the
corruption only shows up when a later exact-match edit mysteriously fails.

Use the `edit` and `write` tools for content. If a bulk mechanical change is
genuinely needed, do it on **bytes**, not strings:

```powershell
$utf8 = New-Object System.Text.UTF8Encoding($false)          # no BOM
$t = [System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes($p))
# ...transform $t...
[System.IO.File]::WriteAllText($p, $t, $utf8)
```

Then prove it, because the failure is silent:

```bash
grep -rlP '\xc3\xa2\xe2\x82\xac' AI/     # empty = no mojibake
head -c3 AI/rules/rust/RUST.md | xxd     # must NOT start with efbbbf
```

## Red flags

- A rule added to `AI/skills/` instead of `AI/rules/`.
- A rule file with no router row pointing at it.
- A rule file with `name:`/`whenToUse:` frontmatter (it is not a skill).
- A task file that restates its general rule instead of pointing at it.
- A `references/` subdirectory in a rule directory — that was the old pack shape;
  rule files sit flat in their directory.
- A symlink anywhere under a shared repo.
- `~/code/dotconfig`, or a private project name, path or port, inside any committed
  file.
- A repo `AGENTS.md` that restates a shared rule instead of routing to it.
- `.agents/local.md` committed, or referenced as if a teammate had it.
- A rule recorded in `.agents/local.md` that the team actually depends on — it
  belongs in the repo's committed `AGENTS.md`.
- A file rewritten by a shell text cmdlet — unless you then proved the em dashes
  and the BOM state survived.

## Why this shape

Glob-scoped rules (Cursor `globs:`, Copilot `applyTo:`, Claude Code `paths:`) fire
when the agent **opens a matching file**. A task-shaped rule ("write an HTTP
endpoint"), a review rule, or an OS rule has no matching path, so it never loads —
and the failure is silent. A router chain plus an explicit switch block reaches
task, OS and repo conditionality, works in every tool that can read a file, and is
verifiable in the transcript: you can see which file was read, and why.
