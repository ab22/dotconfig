# Host facts — Windows

> **Read this at session start when the host is Windows** (`$env:OS` is
> `Windows_NT`, or `uname -s` prints `MINGW*` / `MSYS*` / `CYGWIN*`). Routed from
> `~/HOST.md`.

> **Personal-only.** Describes this config's Windows machines; never vendored into a
> shared repo.

The one-line form of each trap. The depth lives in
`~/.agents/rules/windows/WINDOWS.md`. Delete an entry when it stops being true.

- **Shell: Bash (Git Bash) by default; PowerShell only for Windows-native work** (the
  registry, ACLs, Authenticode, `.ps1`). **Never write a file through a shell**: use the
  Write and Edit tools. Full rule: `windows/WINDOWS.md`, "Which shell".
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
- **Plain `gh issue view` can print nothing in a confined shell** and still exit 0,
  even when redirected to a file. Ask for JSON, which always prints:
  `gh issue view <n> --json title,body,comments --jq '.title, .body' | cat`
  (verified 2026-10-17).
- **Docker Desktop does not start with the machine**, and it is installed per user at
  `%LOCALAPPDATA%\Programs\DockerDesktop`, not under Program Files. After a reboot, start
  `Docker Desktop.exe` from there before anything that needs the engine.
- **C: is nearly full, and its 2 GB page file cannot grow.** The commit limit is about 33 GB
  on 31 GB of RAM. Parallel GPUI/MSVC builds die with `os error 1455` ("paging file too
  small"), and the crash can take the console with it. A full C: also truncates files that
  git or the linker is writing (`LNK1318`, 0-byte sources after a failed `git switch`). Keep
  cargo targets and `TMP`/`TEMP` on E:, and pass `-j 2` / `--build-jobs 2` per build
  (verified 2026-10-18). A page file on E: would lift the limit.
- **Never call a bare `python3` or `py` from the agent shell.** `python3` is the Store
  alias, and with a heredoc either one hung until the 2-minute timeout (verified
  2026-10-17). Use `jq` for JSON; full detail in `windows/WINDOWS.md`.
