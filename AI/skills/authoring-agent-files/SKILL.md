---
name: authoring-agent-files
description: Rules for authoring agent instruction files in dotconfig and delivering them to repos — the machine-global symlink vs committed-copy split, and keeping shared repos free of private dotconfig context. Use when adding or editing an AGENTS.md, an .agents/ module, or a DSH skill, or when vendoring one into a consuming repo.
whenToUse: Creating or updating an agent instruction file (AGENTS.md, .agents/*, a DSH skill) in dotconfig, or vendoring one into a repo.
---

# Authoring agent files

> **Personal-only.** This skill references `dotconfig` and describes this
> machine's layout. It is **never vendored** into a repo — see the table below.

## The one rule

**`dotconfig` is private. The repos are shared.**

Everything below follows from that. A teammate who has never heard of
`dotconfig` must be able to `git clone` a shared repo and have every agent file
in it work.

## Two delivery mechanisms — never mixed

| Mechanism | Allowed for | Never for |
| --- | --- | --- |
| **Symlink**, created by dotconfig's `task install` | paths that live directly under `$HOME` and are yours alone: `~/AGENTS.md`, `~/.dsh/AGENTS.md`, `~/.claude/CLAUDE.md`, `~/.agents/skills` → `AI/skills`, and the editor configs | **anything inside a shared repo** |
| **Committed copy** | every agent file inside a shared repo (`serenity_api`, `serenity_ui`, …) | — |

A symlink from a shared repo into `~/code/dotconfig/...` is **broken for every
other developer and for CI**. The clone succeeds and the files dangle. This is
not a style preference; it is a broken clone.

Equivalently: **no file committed to a shared repo may contain a
`~/code/dotconfig` path.** Such a file may not reference the private repo at
all.

## Where does the content belong?

| The content is… | Home | Delivery to repos |
| --- | --- | --- |
| A machine-global baseline — true in every session, in every project | `AI/AGENTS.md` | symlink only |
| An on-demand procedure, invoked when a task matches | `AI/skills/<name>/` | symlink `~/.agents/skills`; vendor a copy **only if** a plain clone needs it |
| Repo-agnostic and stable — lifecycle, tickets, branching | `AI/agents/<name>.md` | **committed copy**, byte-identical; `diff` is the drift check |
| Language-level conventions | `AI/agents/<lang>.md` | **folded by hand** into each repo's `.agents/<LANG>.md` — deliberately *not* byte-identical |
| Repo-specific — commands, Definition of Done, stack wiring | the repo's own `.agents/` | never comes from dotconfig |
| Personal-only — mentions dotconfig or this machine | `AI/` anywhere | **never vendored**; say so at the top of the file |

## Creating or updating — checklist

1. **Pick the row above before writing anything.**
2. **Edit the canonical file in dotconfig. Never edit a vendored copy in place** —
   the copy is downstream, and the next `cp` silently reverts your change.
3. **Re-vendor** every affected repo, and prove it:
   ```bash
   cp ~/code/dotconfig/AI/agents/<name>.md <repo>/.agents/<NAME>.md
   diff <repo>/.agents/<NAME>.md ~/code/dotconfig/AI/agents/<name>.md   # no output
   ```
4. **Prove no private context leaked** — expect no output, in each repo:
   ```bash
   grep -rn "dotconfig" <repo>/.agents <repo>/AGENTS.md <repo>/scripts
   ```
5. **Register it**, so an agent actually finds it:
   - a skill → the `## Skills` list in `AI/AGENTS.md`;
   - a module → the table in `AI/agents/README.md` **and** the consumer repo's
     `AGENTS.md` "Documentation map";
   - anything repo-facing → the consumer repo's `AGENTS.md` "Documentation map".
6. **If it is a skill**, it must be self-contained: `SKILL.md` frontmatter with
   `name` (matching the directory), `description`, and `whenToUse`; every
   reference inside `<skill>/references/`; links written `references/…`, never
   `../../references/…`.

## Red flags

- A symlink anywhere under a shared repo — `.agents/`, `scripts/`, or the root.
- `~/code/dotconfig` (or `/Users/<you>/code/dotconfig`) inside any committed file.
- A vendored copy that differs from its canonical file with no documented reason —
  either re-vendor it, or record the deliberate divergence next to it.
- A `canonical source: ~/code/dotconfig/...` line in a copy destined for a shared
  repo. Attribution to an *upstream* project with its licence is fine; a path into
  the private repo is not.
- A skill linking `../../references/…` — it breaks the moment the skill is copied
  anywhere.
- Editing a vendored copy instead of the canonical file.

## Why copies, not symlinks

A committed symlink to a private repo is broken for everyone without it. Copies
cost drift — and drift is a mechanical `diff`, caught by a check rather than by
review. That is a price worth paying for a clone that works.
