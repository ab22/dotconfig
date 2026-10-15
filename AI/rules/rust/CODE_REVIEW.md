---
description: Reviewing Rust — the defects a language-agnostic review walks past (unwrap on fallible paths, ignored Result, lossy casts, release-mode overflow, undocumented unsafe), design smells (String for a closed set, format derives on the domain), async hazards, test and dependency red flags, `cfg` code gated to another OS (lint and test it in a container of that OS), and which gates are worth building. Use from rust/RUST.md when reviewing a Rust diff, with gates/CODE_REVIEW.md and the code-review-and-quality skill.
---

> **Read this from `rust/RUST.md` when reviewing Rust.**

# Reviewing Rust

**Load the `code-review-and-quality` skill first.** It owns the method — the five
axes, the severity labels, the structural remedies, and its own per-language
references. This file adds the Rust-specific defects that a language-agnostic
review walks straight past.

**Precedence:** the skill owns the *method*; the rule files own the *conventions*.
Where the skill's `references/code-review-rust.md` and `rust/RUST.md` (or this
file) disagree, the rule file wins — and the repo's own `.agents/RUST.md` wins
over both.

The general axes catch architecture. These catch the bugs.

## Correctness

- **`unwrap()` / `expect()` on anything that can fail at runtime.** Acceptable in a
  test, in a `main` that has already validated, or where the invariant is proven
  immediately above. A silent `unwrap()` on a parse, a lock, a file or a network
  call is a panic waiting for its input.
- **`expect()` with a message that restates the call.** `expect("failed to parse")`
  tells the reader nothing the type did not. Name the *invariant*.
- **Ignored `Result`.** `let _ = …`, a bare expression statement, or `#[must_use]`
  suppressed. Every one is a decision that a failure does not matter — make it
  explicit or handle it.
- **`as` casts between integer widths.** Truncation and sign flips are silent.
  Prefer `TryFrom`/`try_into()`, or prove the range and say so.
- **Arithmetic that can overflow in release.** Debug panics; release wraps. If the
  value is user-controlled or unbounded, use `checked_*`/`saturating_*`.
- **Panic paths in library code:** indexing slices (`v[0]`, `&s[a..b]`), division,
  and `String` slicing that can land mid-character. `get()` returning `Option` is
  the fix; a byte slice on UTF-8 is the trap.
- **`unsafe` without a `// SAFETY:` comment naming the invariant it relies on.**
  An `unsafe` block whose justification is not written down is unreviewable.

## Design

- **A `String` where a closed-set enum belongs.** This file's first rule, and the
  most common finding. Ask what the valid values are; if the answer is a list, it
  is a type.
- **Two tables of strings that must agree.** A `match` producing `"active"` plus a
  serde rename plus a SQL literal is three copies of one fact. See the `rust/RUST.md`,
  "One table of strings, only".
- **A format derive on a domain type.** `Serialize`/`Deserialize`/`sqlx::Type`/
  `FromRow` on the entity rather than on a per-layer type means one layer's spelling
  silently became authoritative.
- **`clone()` used to escape the borrow checker.** Usually a design signal: the
  value is needed in two places at once, so either the ownership is wrong or the
  data should be shared deliberately (`Rc`/`Arc`) with a reason.
- **`&String` / `&Vec<T>` / `&PathBuf` parameters** where `&str` / `&[T]` /
  `&Path` would do. It forces callers to allocate.
- **A generic parameter used once**, or a trait with a single implementor and no
  test seam. Generics are a cost paid by every reader.
- **A `bool` parameter.** `parse(input, true)` is unreadable at the call site; an
  enum with two variants is not.

## Async and concurrency

- **A non-`Send` guard held across an `await`.** `MutexGuard` from `std` across
  `.await` is a compile error in a spawned task or a silent deadlock where it
  compiles. Use the async mutex, or scope the guard.
- **Blocking call inside async:** `std::fs`, `std::thread::sleep`, a blocking
  client, CPU-bound work with no `spawn_blocking`. It stalls the executor for every
  task on that thread.
- **A lock held while awaiting I/O.** Even the async mutex: the lock's job is to
  protect a value, not to serialize a network round trip.
- **`tokio::spawn` where the handle is dropped and no one observes the failure.** A
  panicking task disappears; either join it or log from inside it.
- **An unbounded channel or `join_all` over an unbounded collection.** Memory grows
  with input and nothing applies backpressure.
- **Timeouts on every external call.** A request with no timeout is an outage
  waiting for a slow dependency.

## Tests

- **No test for a changed behaviour** — and under `tdd: on`, no test *first*. See
  the `gates/TDD.md` file.
- **Happy path only.** The invalid/empty/boundary cases are the point; see
  `gates/VALIDATION.md`.
- **A test that asserts on `Debug` output or a message string** rather than the
  typed error. It breaks on a refactor that changed nothing.
- **`#[ignore]` or a commented-out assertion** left behind, with no reason.
- **A test that cannot fail** — asserting a value it just constructed, or an
  `assert!(true)`. Check that the test would go red if the implementation were
  reverted.

## Code gated to another OS

- **`cfg`-gated code for an OS other than the host's is never compiled there.**
  Clippy and the tests on Windows skip every `#[cfg(unix)]` item, and on Linux or
  macOS they skip every `#[cfg(windows)]` one. An unused import or a broken test in
  that code stays invisible until CI or a teammate on the other OS hits it.
- **When the diff adds or changes such code, lint and test it in a container of
  that OS before hand-off**, with the checkout mounted and the repo's own lint and
  test commands — a Linux Rust image from a Windows host, a Windows image from a
  Linux or macOS host.
- **Windows containers need a Windows host.** Where none is available, run
  `cargo clippy --target x86_64-pc-windows-gnu` (after `rustup target add`) at the
  least, and say in the hand-off that the Windows tests did not run.

## Dependencies

- **`Cargo.lock` changed with no `Cargo.toml` change** is still a dependency change:
  read the diff. See the `rust/RUST.md` for the update and advisory rules.
- **A new dependency for something the standard library does.** Each one is
  supply-chain surface and a compile-time cost.
- **Default features left on** for a crate where only one feature is needed.
- **Version pinning inconsistent with the workspace** (`"1.2"` in one crate, `"1"`
  in another) — the remedy is `[workspace.dependencies]`; see `rust/TOOLING.md`.
- **A member `Cargo.toml` without `[lints] workspace = true`** — it silently
  inherits none of the workspace lints.

## Gates worth building

Where a repo has none, these are worth a test rather than a paragraph:

- **Forbidden derives in the domain** — scan the domain sources for `Serialize`,
  `Deserialize`, `sqlx::Type`, `FromRow`. Match **tokens, not paths** (a nested
  `use crate::{ db::X }` contains no `crate::db` literal), **strip comments first**
  or prose false-positives, and **assert the walk found files** — a gate that scans
  nothing passes vacuously.
- **The error-mapping table** — one case per variant, asserting the status code and
  that no internal detail leaks.
- **`clippy` with warnings denied** in CI, so a lint cannot land as a comment.

## What to report

Same shape as the `gates/CODE_REVIEW.md` file: leverage order, severity prefixes, one
explicit verdict. A Rust review that lists ten `clone()` calls and misses one
ignored `Result` on a write path has failed at its job — **lead with the failure
that loses data**.
