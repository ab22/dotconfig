---
description: Rust tooling and verification — the default fmt/clippy/test gate when a repo names none, toolchain and MSRV pinning, editions and the virtual-workspace resolver trap, workspace-level dependencies and lints, additive features, release profiles, build scripts, and CI flags that do not thrash the cache. Use when setting up a crate or workspace, editing a Cargo.toml beyond adding a dependency, touching the toolchain, lints or CI, or deciding what to run before calling Rust work done.
---

> **Read this from `rust/RUST.md` when setting up a crate or workspace, changing manifests, toolchain, lints or CI, or choosing what to run to verify Rust work.**

# Rust tooling and verification

Layer on top of [`RUST.md`](RUST.md). **The repo's own `AGENTS.md` commands win**:
everything here is the default for a repo that names none, and the shape to
propose when setting one up.

## The verify gate

When the repo names no command, this is the gate, cheapest first:

```bash
cargo fmt --all --check
cargo clippy --workspace --all-targets --all-features --locked -- -D warnings
cargo test --workspace --all-features --locked
```

- **`--all-targets`** is what makes clippy lint tests, examples and benches; without
  it a test-only warning lands unseen.
- **`--locked`** fails when `Cargo.lock` would change. In CI that is the point;
  locally, a lockfile change is a dependency change (see `RUST.md`), not noise.
- **`--all-features` assumes features are additive.** If two features are
  mutually exclusive it will not compile — use the repo's feature matrix instead,
  and treat the exclusivity itself as a smell (see *Features*).
- **`cargo nextest run` does not run doc tests.** A repo that uses nextest also
  needs `cargo test --doc`, or a broken `///` example passes the gate.
- Report the commands you ran and their result lines, not "tests pass".
- **`cargo fmt` rewrites files on disk.** Re-read a file it may have touched before the
  next exact-match edit to it, or the edit fails on text that is no longer there.

## Toolchain, edition, MSRV

- **Pin the toolchain in `rust-toolchain.toml`** (`channel`, plus `components =
  ["rustfmt", "clippy"]`), so every machine and CI run the same compiler and lints.
- **`rust-version` in `Cargo.toml` is the MSRV, and raising it is a breaking
  change** for a library's consumers. Bump it deliberately, in its own change, and
  verify with that toolchain (`cargo +<msrv> check`).
- **New crates use the current edition** (2024). Migrate an old one with
  `cargo fix --edition`, as its own change — never mixed with behaviour.
- **A virtual workspace must set `resolver` explicitly.** It has no `edition` to
  infer it from, so it silently falls back to resolver `"1"` (cargo only warns).
  Set `resolver = "3"` for edition-2024 members.

## One workspace, one version of everything

```toml
[workspace.package]
edition = "2024"
rust-version = "1.85"

[workspace.dependencies]
serde = { version = "1", default-features = false }

# each member:  edition.workspace = true
#               rust-version.workspace = true
#               serde = { workspace = true, features = ["derive"] }
```

- **Every shared dependency is declared once** in `[workspace.dependencies]` and
  inherited with `workspace = true`. Two members pinning `"1.2"` and `"1"` is the
  drift this removes.
- **`default-features = false`** where only one feature is needed; members add
  features, they cannot remove them.

## Lints live in the manifest

```toml
[workspace.lints.rust]
unsafe_code = "forbid"                       # unless a crate genuinely needs it

[workspace.lints.clippy]
all = { level = "warn", priority = -1 }      # groups at -1 so single lints override
unwrap_used = "warn"
expect_used = "warn"
await_holding_lock = "deny"
```

- **Each member must opt in with `[lints] workspace = true`.** A member without it
  inherits nothing, silently — check every `Cargo.toml` after adding the table.
- `clippy.toml` with `allow-unwrap-in-tests = true` (and the `expect` twin) keeps
  `unwrap_used` out of test code instead of littering `#[allow]`.
- **Prefer manifest lints to `#![deny(...)]` in `lib.rs`** — one place, every target.
- **Do not deny warnings through `RUSTFLAGS`.** Changing `RUSTFLAGS` changes every
  crate's fingerprint, so switching between a local build and a CI-flagged one
  rebuilds the whole graph. `-- -D warnings` on clippy does the same job.

## Features

- **Features are additive.** Cargo unifies them across the dependency graph, so
  enabling one must never remove API or change existing behaviour. A feature that
  does is a configuration option in the wrong place.
- A crate with real feature-gated code tests the combinations
  (`cargo hack --feature-powerset check` or an explicit matrix), not just default
  and all.

## Profiles

- **Profiles are read from the workspace root only**; a `[profile]` in a member is
  ignored with a warning.
- `panic = "abort"` is a behaviour change (no unwinding, `catch_unwind` stops
  working, `Drop` does not run on panic), not a size optimisation. Decide it.
- `lto`, `codegen-units = 1` and `strip` trade build time for binary size/speed;
  set them for release binaries, never for `dev`.

## Build scripts

- **A `build.rs` declares what it reads** — `cargo::rerun-if-changed=<path>` /
  `rerun-if-env-changed=<VAR>`. Without them it reruns whenever any file in the
  package changes.
- No network access and no writes outside `OUT_DIR`; both break offline and
  sandboxed builds.

## CI

- Same commands as the verify gate, with `--locked`; cache `~/.cargo/registry`,
  `~/.cargo/git` and `target/` keyed on `Cargo.lock` and the toolchain file.
- The dependency/advisory scan (`cargo deny check`, `cargo audit`) runs in the
  extended gate, not the build gate — see `RUST.md`.

On Windows, a build that fails with *Access is denied* or crawls is usually the OS,
not cargo: read `windows/WINDOWS.md` § *Rust on Windows*.
