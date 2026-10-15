# dotconfig

Global configuration for macOS, Arch Linux, other Linux distributions and
Windows, applied with `task install` (`task gen` + `task link`). Both steps are
idempotent: a second run reports `0 linked` and changes nothing.

| platform id | detected when | gets |
| --- | --- | --- |
| `macos` | `uname -s` is `Darwin` | `root/macos/`, editors, agent files |
| `archlinux` | `/etc/os-release` names Arch (`ID` or `ID_LIKE`) | `root/archlinux/` (zsh, sway autostart), editors, agent files |
| `linux` | any other Linux, including WSL | editors and agent files; no shell profile until a `root/linux/` tree exists |
| `windows` | git-bash / MSYS | `root/windows/`, editors in `%LOCALAPPDATA%`/`%APPDATA%`, agent files |

| config | macOS | Arch | other Linux | Windows |
| --- | --- | --- | --- | --- |
| `nvim/`, `nvim-nvchad/`, `zed/`, `vscode/settings.json` | ✓ | ✓ | ✓ | ✓ |
| `alacritty/` (per-OS `alacritty.<os>.toml` + `themes/`), `ghostty/`, `kitty/` | ✓ | ✓ | ✓ | — |
| `i3/`, `i3status/`, `i3status-rs/`, `sway/`, `swaylock/`, `rofi/` | — | ✓ | — | — |

Everything lands under `~/.config/<app>`, except VS Code (`~/Library/Application
Support/Code/User` on macOS, `%APPDATA%\Code\User` on Windows) and the Windows
editor paths below. `task install` also runs `task skills`, which installs the
third-party agent skills listed in `AI/third-party-skills.txt` (needs Node.js).

## Neovim

Two configs coexist, each under its own `NVIM_APPNAME`:

| command  | app name      | source           |
| -------- | ------------- | ---------------- |
| `nvim`   | `nvim`        | `nvim/`          |
| `nvchad` | `nvim-nvchad` | `nvim-nvchad/`   |

`nvchad` is an opt-in trial of [NvChad](https://nvchad.com/); plain `nvim` is
unaffected and is the rollback target. See `nvim-nvchad/README.md` for launch,
update, and exit instructions.

## Windows

The scripts are bash, so on Windows they run under the bash that ships with Git
for Windows. The Taskfile calls it by absolute path, so `task` works from
git-bash, cmd.exe, or PowerShell (as `task.cmd` — bare `task` resolves to
`task.ps1`, which the execution policy blocks). Prerequisites:

| tool    | install                       |
| ------- | ----------------------------- |
| go-task | `npm install -g @go-task/cli` |
| jq      | `winget install jqlang.jq`    |

`task gen` merges `zed/*.base.json` with `zed/*.windows_overrides.json`, and
`task link` links into the paths the Windows builds actually read rather than
`~/.config`:

| source          | target                        |
| --------------- | ----------------------------- |
| `root/windows/` | `%USERPROFILE%`               |
| `nvim/`         | `%LOCALAPPDATA%\nvim`         |
| `nvim-nvchad/`  | `%LOCALAPPDATA%\nvim-nvchad`  |
| `zed/*.json`    | `%APPDATA%\Zed`               |

`root/windows/.bashrc` and `.bash_profile` hold the git-bash equivalents of the
zsh setup other platforms use (PATH for `~/.cargo/bin` and `~/.local/bin`, the
`vim`/`nvchad` aliases, task and direnv hooks), and
`zed/settings.windows_overrides.json` points Zed's integrated terminal at Git's
`bin\bash.exe --login -i`, the same shell `git-bash.exe` launches — so Zed's
console is git-bash rather than Windows PowerShell.

Windows only lets a standard user create symlinks in Developer Mode (Settings →
System → For developers) or from an elevated shell. Without it, `link.sh` links
directories with junctions and files with hardlinks instead — both stay tied to
the repo rather than becoming a copy, but a tool that replaces a config file
wholesale instead of editing it in place can break a hardlink — and so can a
`git pull` that changes the file. `link.sh` records each hardlink it makes in
`~/.local/state/dotconfig/hardlinks`, so re-running `task link` re-links a
recorded file that has drifted (keeping its old contents as
`<file>.dotconfig-bak`). An unrecorded real file is never touched.
