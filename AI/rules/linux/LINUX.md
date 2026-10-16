---
description: Linux traps for agent sessions — a confined shell may map only your user so root-owned files render as nobody and OpenSSH's ownership check on included configs fails git-over-ssh, browser-based test runners find no browser until CHROME_BIN is set, plus case-sensitive paths, inotify watch limits, and GNU-vs-BSD flags. Use when git-over-ssh fails on a Linux box, a browser test cannot find Chrome, or a file watcher stops firing.
---

> **Read this on Linux (WSL included) before writing a shell script, and when git-over-ssh fails, a browser test finds no browser, a watcher stops firing, or a native build fails.**

# Linux traps

> **Personal-only.** This file names one machine's layout and never ships into a
> shared repo.

Entries marked **verified** were reproduced on this workstation, with the date. The
rest are general Linux failure modes, listed because they cost time the same way —
treat them as things to check, not as facts about a specific box.

## git over ssh fails: "Bad owner or permissions" on an ssh config file

**Verified.** Symptom: `ssh`, and `git fetch`/`pull`/`push` over ssh, fail with

```
Bad owner or permissions on /etc/ssh/ssh_config.d/20-systemd-ssh-proxy.conf
fatal: Could not read from remote repository.
```

**Cause.** Agent commands run in a user namespace that maps this machine's user but
**not** root (`uid_map` → `1000 0 1`, `CapEff: 0`), so every root-owned file renders
as `nobody`. Check `/usr/bin/sudo` or `/etc/shadow` and you will see it too.
`/etc/ssh/ssh_config` is just `Include /etc/ssh/ssh_config.d/*.conf`, and OpenSSH
ownership-checks *included* config files — so a root-owned file in that directory
trips the check even though the host is fine.

**Do not chown it.** On the host that file is `root root 644` and ssh + sudo work
normally; `nobody` is only how the sandbox renders root, and `/` is read-only for
agents anyway (`Read-only file system`). A `sudo chown root:root` fixes nothing —
it was a misdiagnosis once, and chasing it cost a session.

**Fix.** Point git at a user-owned ssh config so the system one is never read:

```bash
git config --global core.sshCommand "ssh -F $HOME/.ssh/config"
```

`-F` makes ssh skip `/etc/ssh/ssh_config`, and `~/.ssh/config` (user-owned, 600)
holds the host settings. `git ls-remote origin` then works with no env override.
Bare `ssh git@github.com` still fails, because it reads the system config — `gh`
and the GitHub API over HTTPS were never affected. Verified 2026-09-29 with
OpenSSH 10.5p1.

## A browser test runner cannot find a browser

**Verified.** Symptom: the runner reports no browser available and exits — which,
under piped output, can look like success. Check for the runner's own success line.

**Cause.** No Chrome/Chromium on the default search path.

**Fix.** `export CHROME_BIN=/usr/bin/chromium` (or wherever the binary is), or
install one and set `CHROME_BIN` in the repo's environment file.

**This is the Linux counterpart to the macOS trap.** On macOS the same runner
*cannot start* under `workspace-write` because Chrome keeps state outside the
workspace, and the fix there is a permission preset rather than an env var. Do not
copy either fix across — see `macos/MACOS.md`.

## Case-sensitive paths

Ext4 and friends are case-sensitive, so an import whose case is wrong works on
macOS/Windows and fails here — often only in CI. This is the mirror image of the
APFS trap: a repo with mixed-case filenames and inconsistent imports passes on one
platform and not the other. Check imports against the real filename, and prefer
lowercase paths.

## Line endings must be LF

A file committed with CRLF breaks a shebang (`#!/usr/bin/env bash\r` → "bad
interpreter") and a script that reads config. If a repo has no `.gitattributes`,
add one (`* text=auto eol=lf`) rather than fixing files one at a time.

## Watchers stop firing

`fs.inotify.max_user_watches` and `max_user_instances` are per-user and finite. A
large monorepo, or several dev servers at once, exhausts them and the watcher stops
with no error the app surfaces.

```bash
cat /proc/sys/fs/inotify/max_user_watches     # raise it if a watcher died silently
```

Prefer polling mode for a container or a network mount, where inotify does not
propagate at all — a bind-mounted volume from a host is the classic case, and the
symptom is "my edits don't trigger a rebuild" with no error anywhere.

## GNU tools, not BSD

The inverse of the macOS table: `sed -i`, `date -d`, `grep -P`, `readlink -f`,
`stat -c`, `xargs -r` and `find -printf` all work here and fail on macOS. A script
meant for both should use neither dialect's extensions — see `macos/MACOS.md` for
the side-by-side table.

## Native builds (Rust, Node addons)

- **`linker 'cc' not found`** — no C toolchain. `base-devel` (Arch),
  `build-essential` (Debian/Ubuntu), `@development-tools` (Fedora).
- **`openssl-sys` fails / "Could not find directory of OpenSSL"** — install
  `pkg-config` and the OpenSSL headers (`libssl-dev`, `openssl-devel`), or switch
  the crate to its `rustls` feature where it offers one. Do not set
  `OPENSSL_DIR` by hand to paper over a missing package.

## Ports and permissions

- **Ports below 1024 need a capability** (`CAP_NET_BIND_SERVICE`) or a reverse
  proxy. Binding 80 as a user fails; the error names permissions, not the port.
- **A "port already in use" is usually a previous run.** `lsof -nP -iTCP:<port>
  -sTCP:LISTEN` names the process; do not raise the port number to work around it.
- **A file the app cannot write is often SELinux/AppArmor**, not Unix permissions —
  check `ls -Z` and the audit log before chmod-ing anything.

## Containers and WSL

- **`localhost` inside a container is the container.** A service on the host is at
  `host.docker.internal` (Docker Desktop) or the bridge gateway; a dev server
  bound to `127.0.0.1` instead of `0.0.0.0` is unreachable from outside it. That is
  the most common "it works on my machine" in a containerised stack.
- **Under WSL** the Windows filesystem is at `/mnt/c` and is dramatically slower
  than the Linux one, file watching across the boundary is unreliable, and line
  endings follow the Windows side. Keep the checkout inside the Linux filesystem.

See `~/.agents/hosts/linux.md` (routed from `~/HOST.md`) for the one-liners, and the `windows/WINDOWS.md` / `macos/MACOS.md` files for
the other platforms.
