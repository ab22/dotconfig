# dotconfig

Global configuration for macOS, Arch Linux, and Windows, applied with
`task gen` + `task link`.

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
for Windows: run `task` from a git-bash shell. Prerequisites:

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
wholesale instead of editing it in place can break a hardlink, so re-run
`task link` if a config stops tracking the repo.
