---
description: Windows traps for agent sessions — a confined shell does not inherit the machine's PATH so installed tools look missing, `task` resolves to task.ps1 and the execution policy blocks it, bash is not on PATH, symlinks need Developer Mode while junctions and hardlinks do not, and the sandbox denies spawn-with-piped-stdio so version checks lie. Use when a tool is reported missing, a script will not run, a symlink cannot be created, or a subprocess fails with EPERM on Windows.
---

> **Read this on Windows when a tool looks missing, a script will not run, a symlink cannot be created, or a command fails for an unexplained permission reason.**

# Windows traps

> **Personal-only.** This file names this machine's layout. It is never vendored
> into a shared repo.

Each entry is symptom → cause → fix. Do not re-derive these from first principles:
every one has already cost a session, and each cost more the second time.

## A tool is reported missing and it is installed

**Symptom.** `Get-Command task` returns nothing. `where node` returns nothing.
A repo's own audit agrees: it reports several tools "missing or outdated" — all of
which work on the host.

**Cause — two sandbox artifacts that compound into a convincing false negative.**

1. **A confined shell does not inherit this machine's `PATH`.** DSH starts the
   sandboxed shell with a reduced `PATH` that omits every user-level entry. So
   `Get-Command`, `where` and `$env:Path` *inside a session* are not evidence about
   the host. `~/.cargo/bin` is on the persisted `Path` and absent from the session's
   `$env:Path` — that is the whole bug. Measured: the persisted `Path` has **26**
   entries and a session's has **17**; the 10 dropped include `%APPDATA%\npm` (where
   `task` lives), `.cargo\bin`, and the nvm `.nodejs` directory. **No `DSH_*`
   variable exposes the host `PATH`.**
2. **A spawn-based version check cannot tell the truth under confinement.** A
   script that spawns each tool with piped stdio to read its version hits the
   documented sandbox boundary (EPERM), gets empty output, and reports every tool
   missing. **Any spawn-based check lies the same way.**

**Fix — read the persisted `Path`, which is the truth:**

```powershell
[Environment]::GetEnvironmentVariable('Path','Machine') + ';' +
[Environment]::GetEnvironmentVariable('Path','User')
```

**Never report a tool as absent on a confined `Get-Command` alone.**

**What is installed on this machine** — reachable only through the persisted
`Path`:

| Tool | Location | Note |
| --- | --- | --- |
| `task` (go-task) | `%APPDATA%\npm\task.cmd` | npm's `@go-task/cli`. A **shim that shells out to `node`** — so it needs `node` on `PATH` too, which the sandbox also strips |
| `node` | `%LOCALAPPDATA%\Author Software\nvm\.nodejs` | nvm-managed |
| `cargo`, `rustc` | `%USERPROFILE%\.cargo\bin` | |
| `git`, `gh` | `C:\Program Files\Git\cmd`, `C:\Program Files\GitHub CLI` | |
| `bash` | `C:\Program Files\Git\bin\bash.exe` | **not on `PATH`**. `Git\cmd` is, and it contains no `bash.exe` |

## `task` fails with "running scripts is disabled on this system"

**Cause.** PowerShell resolves the bare name to `task.ps1` — an `ExternalScript`,
which it prefers over `task.cmd` — and the execution policy is `Undefined` at every
scope (Restricted).

**Fix.** Use cmd.exe or git-bash, call `task.cmd` explicitly, or set the policy.
This looks like a missing tool and is not.

## A repo task exits 127, or "bash: executable file not found"

**Cause.** The sub-Taskfile calls `bash` bare, and `C:\Program Files\Git\bin` is
not on `PATH`. A root Taskfile's `BASH=` variable does not reach sub-Taskfiles.

**Fix.** Put `C:\Program Files\Git\bin` on `PATH`, or invoke the absolute path.
`C:\Program Files\Git\cmd` is the directory that *is* on `PATH` — and it has no
`bash.exe`.

## Creating a symlink fails: "Administrator privilege required"

**Symptom.** `New-Item -ItemType SymbolicLink` → `UnauthorizedAccessException`;
`ln -s` under MSYS appears to succeed but produces a **copy**.

**Cause.** Windows grants the "create symbolic links" right only in Developer Mode
or from an elevated shell. A normal user does not have it.

**Fix — three options, in order of preference:**

| Option | Privilege | Notes |
| --- | --- | --- |
| `symlink` | Developer Mode, or elevated | Preferred. Probe it rather than assuming |
| `junction` | none | Directories only; a real reparse point, no copy |
| `hardlink` | none | Files only, same volume; second directory entry, same contents |

`ln -s` under MSYS **silently copies** unless `MSYS=winsymlinks:nativestrict` is
set — so a "successful" `ln -s` is the failure mode to check for with
`[ -L "$dst" ]`. dotconfig's `scripts/link.sh` probes once and falls back in this
order; enable Developer Mode (Settings → System → For developers) so the next run
promotes the junctions and hardlinks to real symlinks.

## A subprocess fails with EPERM for no visible reason

**Cause.** Under a confined sandbox, a program cannot open named pipes. Node's
`child_process.spawn`/`exec` with the default `stdio: 'pipe'` fails with `EPERM`,
while `stdio: 'inherit'` and `stdio: 'ignore'` work, and PowerShell's own pipelines
are unaffected.

**Fix.** Do not retry it another way. Either escalate that exact command once, or
restructure it not to capture output (`inherit`/`ignore`, or run each test file as
its own invocation, which is what dotconfig's Taskfile does).

## Case-insensitive paths, and files Git "changed" for no reason

NTFS is case-insensitive but case-preserving, so `Foo.ts` and `foo.ts` are one
file — and a rename that only changes case needs `git mv` in two steps to be
recorded. Line endings are the other half: a repo with no `.gitattributes` and a
`core.autocrlf` setting will show whole-file diffs on a file nobody edited. Check
`git diff --stat` before believing a file changed.

## Verified

Recorded on this workstation; re-verify a date before trusting an entry after a
tool upgrade.

- `task --version` → go-task 3.54.0; `node --version` → v24.21.0;
  `cargo --version` → 1.99.0.
- `bash --version` works at `C:\Program Files\Git\bin\bash.exe` but not by name.
- A spawn-based tool audit reports 7 false "missing" under `workspace-write`;
  the persisted `Path` shows all present. Verified 2026-10-12.

See `~/HOST.md` for the always-on one-liners, and the `macos/MACOS.md` / `linux/LINUX.md` files for
the other platforms.
