# Neovim config: NvChad trial (opt-in)

An **isolated second Neovim config** for trying [NvChad](https://nvchad.com/)
without touching the hand-rolled config that plain `nvim` uses.

- `../nvim/` — the existing config. Plain `nvim` / `vim`. **Never modified by this trial.**
- `./` (this directory) — the NvChad starter, vendored. Launched as `nvchad`.

## Launch

```sh
task link        # once per machine: symlinks ~/.config/nvim-nvchad -> here
exec zsh         # pick up the alias
nvchad           # NvChad
nvim             # the original config, unchanged
```

The alias lives in `root/<os>/.zshrc`:

```sh
alias nvchad='NVIM_APPNAME=nvim-nvchad nvim'
```

## Why it is isolated

`NVIM_APPNAME` makes Neovim use a whole separate set of directories, so the two
configs never share plugin or state data — and switching never makes lazy.nvim
re-install or prune anything:

|                | original (`nvim`)     | trial (`nvchad`)             |
| -------------- | --------------------- | ---------------------------- |
| config         | `~/.config/nvim`      | `~/.config/nvim-nvchad`      |
| data (plugins) | `~/.local/share/nvim` | `~/.local/share/nvim-nvchad` |
| state          | `~/.local/state/nvim` | `~/.local/state/nvim-nvchad` |

Only the config directory is symlinked into this repo. Data and state stay in
`$HOME` and are safe to delete at any time.

## First launch

NvChad's core (`NvChad/NvChad`, branch `v2.5`) is pulled from GitHub by
lazy.nvim on first start, so the first run needs network access. After it, run:

```
:MasonInstallAll
:TSInstallAll
```

## Requirements

- Neovim **0.11+** (NvChad v2.5's requirement).
- `tree-sitter-cli` — needed for tree-sitter parser installs
  (Arch: `sudo pacman -S tree-sitter-cli`, macOS: `brew install tree-sitter-cli`).
- A Nerd Font terminal font. Prefer the non-`Mono` variant; `*Mono` Nerd Fonts
  render NvChad's icons slightly small.
- `ripgrep` for Telescope's grep (optional).

## Customising

Add plugins to `lua/plugins/init.lua`; options to `lua/options.lua`; keymaps to
`lua/mappings.lua`; theme and UI to `lua/chadrc.lua`. Update NvChad's own core
with `:Lazy sync` inside `nvchad`.

## Updating the vendored starter

`UPSTREAM` records the upstream repo, ref, and the commit last vendored. Run:

```sh
scripts/update-nvchad.sh --dry-run   # report only
scripts/update-nvchad.sh             # apply
```

The script replaces files you have not touched, adds new upstream files, and
removes upstream-deleted files only when unmodified. If you edited a file that
upstream also changed, your version is kept and the new one is written next to
it as `<file>.upstream`; review it, fold in what you want, delete it, and re-run.
`README.md` (this file) is owned by this repo and never synced.

## Leaving the trial

**Discard it** — nothing to undo; the original config was never touched:

```sh
rm -rf ~/.config/nvim-nvchad ~/.local/share/nvim-nvchad ~/.local/state/nvim-nvchad
# then remove the `nvchad` alias from root/<os>/.zshrc
```

The `~/.config/nvim-nvchad` symlink is recreated by `task link`, so removing it
is optional if you may retry later.

**Adopt it** — make `nvim` mean NvChad by changing the alias:

```sh
alias vim='NVIM_APPNAME=nvim-nvchad nvim'
```

A full swap (promoting `nvim-nvchad/` to `nvim/` and retiring the old config) is
deliberately left as a separate, explicit change.

## Credits

Vendored from <https://github.com/NvChad/starter> (MIT — see `LICENSE`).
NvChad's starter was inspired by [LazyVim](https://github.com/LazyVim/starter).
