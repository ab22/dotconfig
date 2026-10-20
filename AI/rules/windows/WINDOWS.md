---
description: Windows shell choice and traps for agent sessions — Bash (Git Bash) by default, PowerShell only for Windows-native work, and never a file written through a shell. Then the traps — a confined shell does not inherit the machine's PATH so installed tools look missing, `task` resolves to task.ps1 and the execution policy blocks it, bash is not on PATH, symlinks need Developer Mode while junctions and hardlinks do not, and the sandbox denies spawn-with-piped-stdio so version checks lie. Also WSL's bash.exe hijacking a bare `bash`, `cmd //c` opening an interactive prompt under `MSYS_NO_PATHCONV=1`, Git Bash rewriting container paths passed to `docker`, `gh` printing nothing without `--json` and PowerShell breaking its `--jq` quotes, pasted commands losing `*` and `X`, line endings, PowerShell 5.1 re-encoding files, Bash-tool heredocs that break on an apostrophe, perl `s|…|…|` turning `\|` into alternation and `s{…}{…}` miscounting Rust braces, deleting a folder that holds junctions, Docker Desktop not running after a reboot, `python` being a Store alias, and Rust on Windows (locked executables, the MSVC linker, Defender, verbatim paths). Use on Windows before picking a shell, before calling a tool missing, before writing a shell script, or when a command, build or symlink fails.
---

> **Read this on Windows before picking a shell, reporting a tool missing or writing a shell script, and when a command, a build or a symlink fails for no visible reason.**

# Windows traps

> **Personal-only.** This file names this machine's layout. It is never vendored
> into a shared repo.

Each entry is symptom → cause → fix. Do not re-derive these from first principles:
every one has already cost a session, and each cost more the second time.

## Which shell

Both shells are useful here, and switching between them at random is where the odd
cases come from. Pick by the work, not by habit.

- **Default: Bash (Git Bash).** This covers repo scripts, `task`, `git`, `gh`, `cargo`,
  `jq`, and anything a Taskfile runs.
- **PowerShell only for Windows-native work:** the registry, ACLs, Authenticode,
  `Get-PSDrive` / `[Environment]`, and running a `.ps1`. Make it a whole PowerShell tool
  call. Don't nest `powershell -Command "…"` inside Bash unless a script has to: the
  nested quoting is its own trap.
- **Never write or rewrite a file through a shell.** No heredoc, `sed -i`, `perl -pi`,
  `Set-Content` or `Out-File`. Use the Write and Edit tools. Use a heredoc only for
  throwaway text, such as a commit message or a comment body in the scratchpad. Each
  shell has corrupted a file here: the heredoc trap below, a Bash-tool heredoc that
  dropped `\\` to `\` even under `<<'EOF'` (verified 2026-10-19), and PowerShell 5.1
  re-encoding UTF-8.
- **Stay in one shell within one task.** Switch only for an exception above, and say why.

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
| `task` (go-task) | `%APPDATA%\npm\task.cmd` | npm's `@go-task/cli`. A **shim that shells out to `node`** — so it needs `node` on `PATH` too, which the sandbox also strips. The real binary, `%APPDATA%\npm\node_modules\@go-task\cli\bin\task.exe`, needs no `node` and works from every shell |
| `node` | `%LOCALAPPDATA%\Author Software\nvm\.nodejs` | nvm-managed |
| `cargo`, `rustc` | `%USERPROFILE%\.cargo\bin` | |
| `git`, `gh` | `C:\Program Files\Git\cmd`, `C:\Program Files\GitHub CLI` | |
| `bash` | `C:\Program Files\Git\bin\bash.exe` | **not on `PATH`**. `Git\cmd` is, and it contains no `bash.exe` |
| Docker Desktop | `%LOCALAPPDATA%\Programs\DockerDesktop\Docker Desktop.exe` | per-user install, not Program Files; **not started at login**. After a reboot `docker` reports `failed to connect to the docker API at npipe:…dockerDesktopLinuxEngine` until it is started. The CLI is `resources\bin\docker.exe` |

## `task` fails with "running scripts is disabled on this system"

**Cause.** PowerShell resolves the bare name to `task.ps1` — an `ExternalScript`,
which it prefers over `task.cmd` — and the execution policy is `Undefined` at every
scope (Restricted).

**Fix.** Call `task.cmd` explicitly from PowerShell or cmd.exe, or set the policy.
This looks like a missing tool and is not.

**Not under git-bash:** there the bare name resolves to npm's `task` sh-shim, which
builds a bad path (`C:\Program Files\Git\Users\...\run-task.js`) and fails, and
`task.cmd` goes through cmd.exe, so the `{a,b}` brace syntax doesn't expand. Put the
real binary first instead:
`export PATH="$APPDATA/npm/node_modules/@go-task/cli/bin:$PATH"`.

## A repo task exits 127, or "bash: executable file not found"

**Cause.** The sub-Taskfile calls `bash` bare, and `C:\Program Files\Git\bin` is
not on `PATH`. A root Taskfile's `BASH=` variable does not reach sub-Taskfiles.

**Fix.** Put `C:\Program Files\Git\bin` on `PATH`, or invoke the absolute path.
`C:\Program Files\Git\cmd` is the directory that *is* on `PATH` — and it has no
`bash.exe`.

**The opposite trap: a bare `bash` that works, but is the wrong one.** With WSL
installed, `C:\Windows\System32\bash.exe` answers to `bash` from cmd.exe and
PowerShell and runs the script **inside WSL** — Linux `uname`, Linux `$HOME`. A
setup script then detects the wrong OS or writes into the WSL home. Call Git's
bash by absolute path (dotconfig's Taskfile does), or check `uname -s` reports
`MINGW*`/`MSYS*` first.

## A Git Bash script hangs in a terminal but "works" for the agent

**Cause.** With `MSYS_NO_PATHCONV=1` (set so `/MIR`, `/J`, `/FI` survive), `cmd //c …`
reaches cmd.exe as `//c`, which it does not recognise: it opens an **interactive
prompt** and waits. A real terminal hangs; the agent shell has no stdin, so cmd exits
at once and the command it was meant to run is silently skipped. Verified 2026-10-16.

**Fix.** Under `MSYS_NO_PATHCONV=1` write `cmd /c`, and close stdin
(`cmd /c … </dev/null`) so a mistake fails instead of hanging. Check the effect (the
junction exists, the file was written), not the exit code.

## A `docker` argument from Git Bash arrives as a Windows path

**Symptom.** A container path in a `docker run` / `docker compose exec` argument becomes
`C:/Program Files/Git/entrypoint.sh`, and a script's error names `/nonexistent` as
`C:/Program Files/Git/nonexistent`.

**Cause.** MSYS rewrites every argument that looks like a POSIX path before it starts a
native exe. Verified 2026-10-17.

**Fix.** Prefix the command with `MSYS_NO_PATHCONV=1`, and turn host paths for
`-v`/`--mount` into Windows form yourself with `cygpath -m "$dir"`. With conversion off,
the `cmd //c` trap above applies.

## `gh` prints nothing, or rejects its `--jq`

**Symptom.** From the Bash tool, `gh issue view <n> --comments` exits 0 and prints
nothing. From PowerShell 5.1, `--jq '"\(.number) \(.title)"'` fails with
`unknown arguments` or `unexpected token "\\"`. Verified 2026-10-17.

**Cause.** With no terminal, the plain view prints nothing. PowerShell 5.1 strips the
embedded double quotes when it passes the argument to a native exe.

**Fix.** Always ask for `--json <fields>`. Filter with `--jq` from Git Bash, or pipe the
JSON to `ConvertFrom-Json` in PowerShell rather than passing a quoted jq filter.

## A command the user pasted into PowerShell runs mangled

**Symptom.** A command handed to the user to paste runs with characters missing: the
regex `.* failed` arrives as `.,`, and the path `20261018\B-webview2` as `20261webview`.
The command then fails, or prints nothing, which looks like a real result. Verified
2026-10-18, twice in one session.

**Cause.** The paste path, not PowerShell, eats `*` and `\` followed by a letter or a
digit.

**Fix.** Write commands for the user to paste with no `*` and no backslash path: use
`-Filter`/`-Recurse` and a literal `Select-String` pattern instead of wildcards, build
paths with `Join-Path` or forward slashes, or put the command in a `task` recipe or a
script file. If the output is empty or an error names a path you did not write, ask for
the command line as it ran before you read anything into the result.

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

**A hardlink silently stops tracking** the moment git or an editor *replaces* the
file instead of writing into it: the other entry keeps the old inode and now looks
like an ordinary file. `link.sh` records the hardlinks it made and re-links a
drifted one on the next run; any other tool's hardlink needs the same care.
`[ a -ef b ]` is the check that two paths are still one file.

## Deleting a folder that holds junctions

**Risk.** Windows PowerShell 5.1's `Remove-Item -Recurse` can follow a junction and
delete its *target's* contents. From Git Bash, `cmd /c "rmdir \"$j\""` fails on the
quoting ("syntax is incorrect") and deletes nothing.

**Fix.** Unlink each junction first, then delete the rest, from PowerShell:

```powershell
Get-ChildItem -LiteralPath $dir -Recurse -Directory -Attributes ReparsePoint |
  ForEach-Object { [System.IO.Directory]::Delete($_.FullName, $false) }  # removes the link only
[System.IO.Directory]::Delete($dir, $true)   # once no reparse point is left
```

Check that the target still has its files afterwards. Verified 2026-10-16.

## A subprocess fails with EPERM for no visible reason

**Cause.** Under a confined sandbox, a program cannot open named pipes. Node's
`child_process.spawn`/`exec` with the default `stdio: 'pipe'` fails with `EPERM`,
while `stdio: 'inherit'` and `stdio: 'ignore'` work, and PowerShell's own pipelines
are unaffected.

**Fix.** Do not retry it another way. Either escalate that exact command once, or
restructure it not to capture output (`inherit`/`ignore`, or run each test file as
its own invocation so no single process has to capture the others).

## Case-insensitive paths, and files Git "changed" for no reason

NTFS is case-insensitive but case-preserving, so `Foo.ts` and `foo.ts` are one
file — and a rename that only changes case needs `git mv` in two steps to be
recorded.

**Line endings.** This machine has `core.autocrlf=true`, so a repo with no
`.gitattributes` is checked out CRLF. Git-for-Windows bash tolerates a CRLF script;
WSL, Linux and macOS do not (`$'\r': command not found`, `bad interpreter`). A
fixture read with `include_str!`/`readFileSync` also gains `\r`, so a string
equality test fails on Windows only. The fix is a committed `.gitattributes`
(`* text=auto eol=lf`), not per-file conversion. Check `git ls-files --eol` and
`git diff --stat` before believing a file changed.

**Never rewrite a text file with Windows PowerShell 5.1's `Get-Content` →
`Set-Content`.** It reads UTF-8 as cp1252 and writes it back, turning every em
dash into three characters, and `-Encoding UTF8` adds a BOM. Use the edit tools;
the byte-level recipe is in the `authoring-agent-files` skill.

## Python crashes with `UnicodeEncodeError: 'charmap' codec`

**Cause.** The console is cp1252, so `print` of any non-ASCII text (`→`, `—`, `…`)
raises. Setting `PYTHONIOENCODING=utf-8` does nothing under `py -I`: isolated mode
ignores every `PYTHON*` variable.

**Fix.** In the script, before the first print: `sys.stdout.reconfigure(encoding="utf-8")`.
Write files with an explicit `encoding="utf-8"` too; the default is the codepage.

## A Bash-tool heredoc fails: "unexpected EOF while looking for matching `'`"

**Symptom.** A multi-line `cat >> f <<'EOF' … EOF` sent through the agent's Bash tool
fails to parse when the text holds an apostrophe (`the client's`), quoted delimiter
or not. Nothing is written. Verified 2026-10-16.

**Fix.** Write the text with the Write tool to a scratchpad file, then
`cat "$scratch" >> f`. Keep heredocs for throwaway text with no `'` (see
[Which shell](#which-shell)). Multi-line Rust nearly always
holds one (lifetimes, `'static`, doc prose), so write source files with the Write tool,
never a heredoc.

**perl `s|…|…|` corrupts Markdown tables.** With `|` as the delimiter, an escaped `\|`
in the pattern is regex alternation, not a literal pipe, so the substitution matches
the empty string and inserts rows at the top of the file. Use `s{…}{…}`, or the Edit
tool. Verified 2026-10-16.

**perl `s{…}{…}` breaks on Rust.** A pattern or replacement holding an unbalanced or
escaped `{`/`}` (a block, a format string, a struct literal) miscounts the delimiters, and
`\t` in a replacement writes a literal tab into a Rust string. For Rust source use the
Edit tool, or a perl script with `/` delimiters. Verified 2026-10-17.

**`python` is not Python here.** `python`/`python3` are the Microsoft Store aliases
(exit 49, "Python was not found"). Query JSON with `jq`, which is on `PATH`. From the
agent's Bash tool, a bare `python3` or `py` fed a heredoc hung until the 2-minute timeout
instead of failing. Verified 2026-10-17.

## Rust on Windows

General Windows behaviour rather than one-off observations — check, do not assume.

- **`cargo build` fails with *Access is denied (os error 5)* or cannot remove
  `target\debug\<name>.exe`.** Windows locks a running executable: a server left
  running, a debugger, a test binary still alive. Stop that process
  (`Get-Process <name> | Stop-Process`); `cargo clean` fixes nothing.
- **`linker 'link.exe' not found`.** The default `*-pc-windows-msvc` toolchain needs
  the Visual Studio Build Tools (*Desktop development with C++*). If the error
  instead reads `link: extra operand`, the MSVC linker was not found and Git's GNU
  `link.exe` on `PATH` answered — repair the Build Tools; do not reorder `PATH`.
- **Builds crawl.** Defender scans every file written to `target\`. A Dev Drive, or
  a Defender exclusion for `target\` and `%USERPROFILE%\.cargo`, fixes it — **an
  exclusion is a security decision: ask the user, never set it yourself.**
- **`std::fs::canonicalize` returns `\\?\C:\...`** (a verbatim path). Other tools,
  `Display` output and string comparisons choke on it; use `dunce::canonicalize`
  or avoid canonicalising.
- **Paths are built with `Path::join`**, never by formatting `"{dir}/{file}"`; and
  `tokio::signal::unix` does not exist here — gate it with `#[cfg(unix)]`.
- **Deep `target\` or `node_modules` paths pass 260 characters.** Enable long paths
  in Windows and `git config --global core.longpaths true` before blaming the tool.

## Verified

Recorded on this workstation; re-verify a date before trusting an entry after a
tool upgrade.

- `task --version` → go-task 3.54.0; `node --version` → v24.21.0;
  `cargo --version` → 1.99.0.
- `bash --version` works at `C:\Program Files\Git\bin\bash.exe` but not by name.
- A spawn-based tool audit reports 7 false "missing" under `workspace-write`;
  the persisted `Path` shows all present. Verified 2026-10-12.
- Developer Mode on (`AllowDevelopmentWithoutDevLicense = 1`); `link.sh` makes
  real symlinks. No `System32\bash.exe` (WSL bash absent). Both Git-for-Windows
  and MSYS2 bash run CRLF scripts. Go-task's built-in shell reports no `.exe` as
  executable to `[ -x ]` — test with `[ -f ]`. Verified 2026-10-14.

See `~/.agents/hosts/windows.md` (routed from `~/HOST.md`) for the one-liners, and the `macos/MACOS.md` / `linux/LINUX.md` files for
the other platforms.
