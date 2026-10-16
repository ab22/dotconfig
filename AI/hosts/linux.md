# Host facts — Linux

> **Read this at session start when the host is Linux, WSL included** (`uname -s`
> prints `Linux`). Routed from `~/HOST.md`.

> **Personal-only.** Describes this config's Linux machines; never vendored into a
> shared repo.

The one-line form of each trap. The depth lives in
`~/.agents/rules/linux/LINUX.md`. Delete an entry when it stops being true.

- **git over ssh needs `core.sshCommand = ssh -F ~/.ssh/config`.** A confined shell
  maps your user but not root, so root-owned files in `/etc/ssh/ssh_config.d/` render
  as `nobody` and OpenSSH's ownership check fails the connection. **Do not chown
  them** — the host is fine; that was a misdiagnosis that cost a session. Full
  detail: `linux/LINUX.md`.
- **A browser test needs `CHROME_BIN`** — no browser is found otherwise, and the
  failure can look like success under piped output.
