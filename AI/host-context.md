# Host context for AI agents

> **Personal-only.** This file describes one machine and is never vendored into a
> shared repo. `task link` symlinks it to `~/HOST.md`, and `AI/AGENTS.md` points
> every session at it.

Machine-specific facts an agent should know **before** it burns a session
rediscovering them. This is not a standard and not a rule set — it is a list of
"the environment is shaped like this; don't fight it" notes.

**Keep this file small.** It is always in context. Only what must be known *before*
opening a file belongs here — the one-line form of each trap. The depth lives in
the OS rule files (`~/.agents/rules/{windows,macos,linux}/`); when an entry here
grows past a few lines, move it there.

**Current host: Windows.** The macOS and Linux sections are kept because this
config is used on those machines too; they cost a few lines each and save
rediscovering a trap on a machine you are not sitting at.

Delete an entry when it stops being true. A stale host fact is worse than a missing
one.

---

## Windows (current host)

- **A confined shell does not inherit this machine's `PATH`.** `Get-Command`,
  `where` and `$env:Path` inside a session are not evidence about the host, and a
  spawn-based version check returns empty for every tool — so a repo's own audit can
  report working tools as missing. **Read the persisted `Path`** (Machine + User)
  before believing a tool is absent. Full detail: `windows/WINDOWS.md`.
- **`bash` is not on `PATH`.** `C:\Program Files\Git\cmd` is, and holds no
  `bash.exe`; the binary is `C:\Program Files\Git\bin\bash.exe` (dotconfig's
  Taskfile calls it by that path). Under PowerShell, bare `task` resolves to
  `task.ps1` and the execution policy blocks it — call `task.cmd`.
- **Developer Mode is on**, so `link.sh` makes real symlinks (verified 2026-10-14).
  Without it, it falls back to junctions and hardlinks — see `windows/WINDOWS.md`.
- **Useful commands live at** `%APPDATA%\npm\task.cmd` (go-task via npm),
  `%LOCALAPPDATA%\Author Software\nvm\.nodejs` (node), `%USERPROFILE%\.cargo\bin`
  (cargo), `C:\Program Files\GitHub CLI` (gh).

## macOS

- **A browser-based test runner cannot start under `workspace-write`** — Chrome
  keeps its profile and crash dumps outside the workspace, and DSH has no
  per-command allow-rule to grant it. **Its exit code is `0` when output is piped, so
  a run that executed nothing looks green** — check for the runner's own success
  line. The fix is a session permission preset, never a committed config change.
  Full detail: `macos/MACOS.md`.
- **The toolchain is BSD**, so GNU flags (`sed -i`, `date -d`, `readlink -f`) fail —
  often silently.
- **Apple Silicon Homebrew is `/opt/homebrew`**, not `/usr/local`.

## Linux

- **git over ssh needs `core.sshCommand = ssh -F ~/.ssh/config`.** A confined shell
  maps your user but not root, so root-owned files in `/etc/ssh/ssh_config.d/` render
  as `nobody` and OpenSSH's ownership check fails the connection. **Do not chown
  them** — the host is fine; that was a misdiagnosis that cost a session. Full
  detail: `linux/LINUX.md`.
- **A browser test needs `CHROME_BIN`** — no browser is found otherwise, and the
  failure can look like success under piped output.

## All platforms

- **A piped test or tool run can report success without doing anything.** Assert on
  the runner's own success line, or on the content the caller needs — never on the
  exit code alone.
- **The checked-in `.gitignore` rules only remove a path from *tracking*, not from
  `git status`.** This machine's global ignore (`~/.gitignore` →
  `dotconfig/root/.gitignore`) is what hides `.agents/local.md`; `git check-ignore
  -v <path>` names the rule responsible, in any repo.
