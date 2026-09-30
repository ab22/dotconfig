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
