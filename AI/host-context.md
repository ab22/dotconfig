# Host context for AI agents

Personal-only: this file describes one machine and is never vendored into a shared
repo. `task link` symlinks it to `~/HOST.md`, and DSH loads it via
`instructionFileCandidates`.

Machine-specific facts an agent should know **before** it burns a session
rediscovering them. This is not a standard and not a rule set — it is a list of
"the environment is shaped like this; don't fight it" notes for this workstation.

If an entry here is fixed, delete it rather than leaving it stale.

---

## Agent sessions can't read the system ssh config (sandbox artifact, not a host bug)

**Symptom.** `ssh`, and `git fetch`/`pull`/`push` over ssh, fail in agent sessions
with `Bad owner or permissions on /etc/ssh/ssh_config.d/20-systemd-ssh-proxy.conf`
plus `fatal: Could not read from remote repository.`

**Cause.** Agent commands run in a user namespace that maps this machine's user but
**not** root (`uid_map` → `1000 0 1`, `CapEff: 0`), so every root-owned file renders
as `nobody` — check `/usr/bin/sudo` or `/etc/shadow` and you will see it too.
`/etc/ssh/ssh_config` is just `Include /etc/ssh/ssh_config.d/*.conf`, and OpenSSH
ownership-checks *included* config files, so the root-owned
`20-systemd-ssh-proxy.conf` trips the check.

**Do not chown it.** On the host that file is `root root 644` and ssh + sudo work
normally; `nobody` is only how the sandbox renders root, and `/` is read-only for
agents anyway (`Read-only file system`). The `sudo chown root:root` that an earlier
version of this file prescribed fixes nothing — it was a misdiagnosis, and chasing
it cost a session.

**Git is already fixed.** `~/.gitconfig` sets
`core.sshCommand = ssh -F /home/abe/.ssh/config`; `-F` makes ssh skip
`/etc/ssh/ssh_config`, and `~/.ssh/config` (user-owned, 600) holds git-over-ssh host
settings. `git ls-remote origin` works with no env override, so fetch/pull/push all
do. Bare `ssh git@github.com` still fails, since it reads the system config; `gh`
and the GitHub API over HTTPS were never affected.

Verified 2026-09-29 with OpenSSH 10.5p1.

---

## Karma's Chrome cannot start under `workspace-write`, and there is no per-command fix (macOS)

**Symptom.** In a `workspace-write` session, `npx ng test --watch=false` dies before
running a test: `sandbox initialization failed: Operation not permitted`,
`GPU process isn't usable. Goodbye.`, and `open ~/Library/Application
Support/Google/Chrome/Crashpad/settings.dat: Operation not permitted`, ending in
`ChromeHeadless failed 2 times (cannot start)`. Two traps hide it. Karma's **exit code
is 0 when its output is piped**, so a run that executed nothing still looks like it
passed — check for the `TOTAL: … SUCCESS` line. And the fix is an escalation request,
so a denied approval reads as a silent no-op rather than an error.

**Cause.** Chrome keeps its profile, crash dumps and GPU state under
`~/Library/Application Support/Google/Chrome`, outside the session workspace, so the
confined call needs escalation. DSH cannot pre-authorize that, and this is a documented
limitation rather than a missing knob:

- `@deepseek-ai/dsh-sandbox-policy`: *"One primary workspace root per session — policy
  resolves `SessionHeader.cwd`; extra writable roots are not part of
  `SandboxExecutionPolicy`."* Its config accepts only `mode` and `workspaceRoot`.
- `@deepseek-ai/dsh-user-approval`: *"Only one-shot grants exist — … no `allow-always`,
  remembered rule, revocation, or grant store; session policy is only `ask` /
  `never`."*

So do **not** hunt for a per-command allow-rule to add to
`~/.dsh/profiles/<p>/cordis.patch.yml`, and do not set `policy: never` hoping to silence
the prompt: `never` **rejects** escalations, so the tests would fail instead of run. The
only lever is the session's permission preset, which sets the sandbox mode and the
approval policy together.

**Fix, in order of preference.**

1. **Switch the session's preset:** `/permission danger-full-access`. It applies to that
   session only (recorded in its log, survives its restart) and carries
   `approval: never`, so nothing prompts. The shipped presets are `read-only`,
   `workspace-write` and `danger-full-access`.
2. **Launch with the mode set:**
   `DSH_PERMISSION_MODE=danger-full-access dsh --profile <name>`. The base profile
   already reads that variable for both `sandbox-policy.mode` and the approval policy, so
   this needs no profile edit.
3. **Approve the escalation per run** — what `serenity_ui/.agents/ANGULAR.md` ("Local
   environment") documents. That is the point of `workspace-write`: the escalation is
   asked rather than assumed.

Options 1 and 2 are deliberately opt-in and session-scoped. Do not lower the *default*
mode in a profile patch to make unit tests quiet: that drops file confinement for every
session in every repo, which is a far larger change than this inconvenience justifies.

**Do not put the workaround in the repo.** Chrome flags in `serenity_ui/karma.conf.js`
would bake this machine's sandbox workaround into a shared file, which
`serenity_ui/.agents/ANGULAR.md` ("Local environment — not project conventions")
explicitly rules out. (The Linux box has a different failure — no browser found, fixed
with `CHROME_BIN=/usr/bin/chromium` — and needs none of this.)

Verified 2026-10-04 on Chrome 153 headless: `dsh --profile desktop --dump-config`
(`sandbox-policy.mode`, `approval.policy`, `permission.presets`) plus the
`npx ng test --watch=false` pair (blocked in `workspace-write`, then `TOTAL: 829 SUCCESS`
under the wider sandbox).
