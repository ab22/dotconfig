# Host context for AI agents

> **Personal-only.** This file describes this config's machines and is never
> vendored into a shared repo. `task link` symlinks it to `~/HOST.md`, and
> `AI/AGENTS.md` points every session at it.

Machine-specific facts an agent should know **before** it burns a session
rediscovering them. This is not a standard and not a rule set — it is a list of
"the environment is shaped like this; don't fight it" notes.

The same file is linked on every machine, so it does **not** name the current OS.
It routes to the OS's own host file instead.

## Detect the OS, then read its host file — before the first command

Take the platform from the harness's environment block; without one, run
`uname -s` (PowerShell: `$env:OS`).

| Detected | Read now |
| --- | --- |
| `Darwin` / `darwin` | `~/.agents/hosts/macos.md` |
| `Linux` / `linux`, WSL included | `~/.agents/hosts/linux.md` |
| `Windows_NT`, `win32`, `MINGW*` / `MSYS*` / `CYGWIN*` | `~/.agents/hosts/windows.md` |

That OS's row in the `AI/AGENTS.md` router (`~/.agents/rules/<os>/`) is then live all
session. `~/.agents/hosts` is a link to `AI/hosts/` made by `task install`; if it is
missing, say so and ask for `task install` rather than guessing at the facts.

**Keep these files small.** Only what must be known *before* opening a file belongs
in them — the one-line form of each trap. The depth lives in the OS rule files
(`~/.agents/rules/{windows,macos,linux}/`); when an entry grows past a few lines,
move it there. Delete an entry when it stops being true. A stale host fact is worse
than a missing one.

## All platforms

- **A piped test or tool run can report success without doing anything.** Assert on
  the runner's own success line, or on the content the caller needs — never on the
  exit code alone.
- **The checked-in `.gitignore` rules only remove a path from *tracking*, not from
  `git status`.** This machine's global ignore (`~/.gitignore` →
  `dotconfig/root/.gitignore`) is what hides `.agents/local.md`; `git check-ignore
  -v <path>` names the rule responsible, in any repo.
