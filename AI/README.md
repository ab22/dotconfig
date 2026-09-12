# AI (agent configuration)

Shared, repo-agnostic agent configuration used across projects: the global
`AGENTS.md`, the skills, and the instruction modules that a project's `AGENTS.md`
/ `.agents/` files reference.

**CLI tools do not live here.** They are a separate repository
(`agent-toolkit`) installed as regular user binaries into `~/.local/bin`; see its
`README.md`.

## Layout

| Path | Purpose |
| --- | --- |
| `AGENTS.md` | The machine-global agent baseline (symlinked to `~/AGENTS.md`, `~/.dsh/AGENTS.md`, `~/.claude/CLAUDE.md`). |
| `agents/` | Shared agent-instruction modules that project `AGENTS.md` / `.agents/` files can reference. |
| `skills/` | DSH skills (symlinked to `~/.agents/skills`). |

## Tools

`gh-plan`, `plan`, `preflight`, `handoff` and `dod` ship in `agent-toolkit`:

```bash
cd ~/code/agent-toolkit && task install     # → ~/.local/bin
task verify-install                         # after a shell/harness restart
```

`gh-plan` is additionally vendored into each project repo at `scripts/gh-plan`,
so a plain clone needs no extra checkout.

## Install

```bash
cd ~/code/dotconfig && task install
```

Links the global agent files, the skills, the shell profiles (including
`~/.local/bin` on `$PATH`) and the editor configs, and runs the `agent-toolkit`
installer when that repo is present.
