# Host facts — macOS

> **Read this at session start when the host is macOS** (`uname -s` prints
> `Darwin`). Routed from `~/HOST.md`.

> **Personal-only.** Describes this config's Mac; never vendored into a shared repo.

The one-line form of each trap. The depth lives in
`~/.agents/rules/macos/MACOS.md`. Delete an entry when it stops being true.

- **Apple Silicon (arm64).** Homebrew is `/opt/homebrew`, not `/usr/local`, and
  Docker runs arm64 Linux containers — CI runners are usually x86_64.
- **Docker Desktop is reachable from the agent shell** (verified 2026-10-15), so
  `docker compose` and recipes built on it run in-session. Where a repo targets
  Linux, its tests run in Docker here, not natively.
- **A browser-based test runner cannot start under `workspace-write`** — Chrome
  keeps its profile and crash dumps outside the workspace, and DSH has no
  per-command allow-rule to grant it. **Its exit code is `0` when output is piped, so
  a run that executed nothing looks green** — check for the runner's own success
  line. The fix is a session permission preset, never a committed config change.
  Full detail: `macos/MACOS.md`.
- **The toolchain is BSD**, so GNU flags (`sed -i`, `date -d`, `readlink -f`) fail —
  often silently. `/bin/bash` is 3.2.
