# dotconfig

Global configuration for macOS and Arch Linux, applied with `task gen` +
`task link`.

## Neovim

Two configs coexist, each under its own `NVIM_APPNAME`:

| command  | app name      | source           |
| -------- | ------------- | ---------------- |
| `nvim`   | `nvim`        | `nvim/`          |
| `nvchad` | `nvim-nvchad` | `nvim-nvchad/`   |

`nvchad` is an opt-in trial of [NvChad](https://nvchad.com/); plain `nvim` is
unaffected and is the rollback target. See `nvim-nvchad/README.md` for launch,
update, and exit instructions.
