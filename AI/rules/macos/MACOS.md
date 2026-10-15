---
description: macOS traps for agent sessions — a browser-based test runner (Karma/Chrome) cannot start under the workspace-write sandbox because Chrome keeps state outside the workspace, its exit code is 0 when output is piped so a suite that never ran looks green, and there is no per-command allow-rule to add. Also covers case-insensitive APFS, BSD vs GNU tool flags, Homebrew paths, and CRLF. Use when a test runner fails to start on macOS, a version check lies, or a BSD-vs-GNU flag error appears.
---

> **Read this on macOS before writing a shell script, and when a browser-based test will not start, a version check lies, a tool flag fails, or a build cannot find its linker.**

# macOS traps

> **Personal-only.** This file names one machine's layout and never ships into a
> shared repo.

## Karma/Chrome "sandbox initialization failed" — and the green run that never ran

**Symptom.** Under `workspace-write`, `npx ng test --watch=false` dies before
running a test:

```
sandbox initialization failed: Operation not permitted
GPU process isn't usable. Goodbye.
open ~/Library/Application Support/Google/Chrome/Crashpad/settings.dat: Operation not permitted
ChromeHeadless failed 2 times (cannot start)
```

**Two traps hide it:**

1. **The exit code is `0` when the output is piped.** A run that executed nothing
   looks like it passed. **Check for the runner's own `TOTAL: … SUCCESS` line**, not
   the exit code.
2. **The fix is an escalation request**, so a denied approval reads as a silent
   no-op rather than an error.

**Cause.** Chrome keeps its profile, crash dumps and GPU state under
`~/Library/Application Support/Google/Chrome`, outside the session workspace, so
the confined call needs escalation. **DSH cannot pre-authorize it, and this is a
documented limitation rather than a missing knob:**

- `@deepseek-ai/dsh-sandbox-policy`: *"One primary workspace root per session —
  policy resolves `SessionHeader.cwd`; extra writable roots are not part of
  `SandboxExecutionPolicy`."* Its config accepts only `mode` and `workspaceRoot`.
- `@deepseek-ai/dsh-user-approval`: *"Only one-shot grants exist — … no
  `allow-always`, remembered rule, revocation, or grant store; session policy is
  only `ask` / `never`."*

**Do not** hunt for a per-command allow-rule in
`~/.dsh/profiles/<p>/cordis.patch.yml`, and do not set `policy: never` hoping to
silence the prompt — `never` **rejects** escalations, so the tests would fail
instead of run.

**Fix, in order of preference:**

1. **Switch the session's permission preset:** `/permission danger-full-access`. It
   applies to that session only and carries `approval: never`, so nothing prompts.
   The shipped presets are `read-only`, `workspace-write`, `danger-full-access`.
2. **Launch with the mode set:** `DSH_PERMISSION_MODE=danger-full-access dsh
   --profile <name>` — the base profile reads that variable for both
   `sandbox-policy.mode` and the approval policy, so no profile edit is needed.
3. **Approve the escalation per run** — the point of `workspace-write` is that the
   escalation is asked rather than assumed.

Options 1 and 2 are deliberately session-scoped. **Do not lower the default mode in
a profile patch to make unit tests quiet** — that drops file confinement for every
session in every repo.

**Do not put the workaround in the repo.** Chrome flags in a committed
`karma.conf.js` bake one workstation's sandbox workaround into a file every
teammate clones. (On Linux the failure is different — no browser found, fixed with
`CHROME_BIN=/usr/bin/chromium` — and needs none of this.)

## BSD tools, not GNU

macOS ships BSD `sed`, `awk`, `grep`, `find`, `date`, `xargs`, `stat` and `cp`.
Scripts written against GNU flags fail here, often silently:

| GNU | macOS |
| --- | --- |
| `sed -i 's/a/b/'` | `sed -i '' 's/a/b/'` — the suffix argument is **required** |
| `date -d '2024-01-01'` | `date -j -f '%Y-%m-%d' '2024-01-01'` |
| `grep -P` | not supported — use `-E`, or install GNU grep |
| `readlink -f` | `readlink` has no `-f`; use `realpath` |
| `stat -c` | `stat -f` |
| `xargs -r` | `xargs` runs once with no input; no `-r` |
| `cp --parents` | not supported |
| `find -printf` | not supported |

**Write POSIX, or detect.** A shell script intended to run on Linux too should not
rely on either dialect's extensions. `brew install coreutils` gives `g`-prefixed
GNU tools (`gsed`, `gdate`) when a script needs one.

**`/bin/bash` is 3.2.** A `#!/usr/bin/env bash` script gets it unless Homebrew's
bash is first on `PATH`, so bash-4+ features fail on a stock Mac: `mapfile` /
`readarray`, associative arrays (`declare -A`), `${var,,}` / `${var^^}`, `|&`, and
negative array indices. dotconfig's scripts stay within 3.2 for that reason.

## Paths and the filesystem

- **APFS is case-insensitive by default but case-preserving.** `Foo.ts` and
  `foo.ts` are one file, so a case-only rename needs `git mv` in two steps — and an
  import with the wrong case works locally and breaks CI.
- **Unicode normalisation is NFD.** A filename with accents is stored decomposed, so
  a byte comparison against an NFC string fails. Compare normalised forms.
- **`/tmp` is a symlink to `/private/tmp`.** `pwd` and `pwd -P` differ; a script that
  compares paths needs the resolved form.
- **CRLF.** A repo with no `.gitattributes` and `core.autocrlf=input` shows
  whole-file diffs on files nobody edited. Check `git diff --stat` first.

## Homebrew, Python and Xcode

- **Apple Silicon Homebrew is `/opt/homebrew`**, not `/usr/local`. A script with a
  hardcoded `/usr/local/bin` silently picks the Intel location — which may exist and
  be stale.
- **The system Python is not for installing into.** `pip install` without a venv
  fails (externally-managed environment) or installs somewhere `python3` does not
  look. Use a venv or `pipx`.
- **`xcrun`/`git` need the Command Line Tools.** If `git` is missing on a fresh
  machine, `xcode-select --install` is the answer, not a Homebrew git. The same
  fix applies when `cargo build` fails with `linker 'cc' not found` or an
  `xcrun: error: invalid active developer path` after a macOS upgrade.

## Verified

- Verified 2026-10-04 on Chrome 153 headless: `dsh --profile desktop --dump-config`
  (`sandbox-policy.mode`, `approval.policy`, `permission.presets`), plus the
  `npx ng test --watch=false` pair — blocked under `workspace-write`, then
  `TOTAL: 829 SUCCESS` under the wider sandbox.

See `~/HOST.md` for the always-on one-liners, and `windows/WINDOWS.md` /
`linux/LINUX.md` for the other platforms.
