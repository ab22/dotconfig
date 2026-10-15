---
description: Rust command-line tools — a derived argument parser converted into domain types before any work, exit codes as API (0/1/2), stdout for data and stderr for everything else, one top-level error printer, explicit config precedence, and tests that assert exit codes and both streams. Use from rust/RUST.md when the Rust code is a command-line tool.
---

> **Read this from `rust/RUST.md` when the Rust code is a command-line tool.**

# Rust for command-line tools

Layer on top of the `rust/RUST.md` — the enum, domain and error rules there all
apply. This reference adds the CLI concerns: the argument model, exit codes, and
the stdout/stderr contract.

## Arguments are a parsed type, not strings

The same "parse, don't validate" rule as the rest of this file, at the process
boundary:

- **Derive the parser struct** (`clap` and friends), so `--help`, `--version`,
  shell completion and error messages come from one declaration.
- **A closed set of options is an enum**, not a `String` compared in three places.
- **Convert the parsed args into a domain type before doing work.** `main` reads
  args, converts once, then calls a function that takes real types. That function
  is unit-testable with no `argv`.
- **A required argument is required by the parser**, not checked with an `if` after
  the fact — a missing value should fail before any side effect, with usage text.
- **`--flag` and its negation are two states, not a tri-state.** If you need
  "unset" as well as true/false, model it as `Option<bool>` and say what unset
  means (see the `gates/VALIDATION.md` file).

## Exit codes are the interface

A script calling this tool branches on the exit code, so it is API:

| Code | Meaning |
| --- | --- |
| `0` | success |
| `1` | the operation ran and failed (a domain failure) |
| `2` | the invocation was wrong — bad flag, bad usage |
| other | reserve it deliberately and document it; do not invent codes ad hoc |

- **Return the code from `main`** (`ExitCode`, or `std::process::exit` in one place
  at the very end), so a failure path cannot fall through to `0`.
- **Printing an error is not failing.** A tool that prints `error: …` and exits `0`
  breaks every caller; this is the most common defect in a new CLI.
- Similarly, **a non-zero exit with no message** is unactionable. Both, always.

## stdout is data, stderr is everything else

- **stdout carries the result** — the thing being piped. Nothing else.
- **stderr carries progress, warnings, diagnostics and errors.** A progress
  spinner on stdout corrupts the output of the command being piped.
- **Respect the terminal.** Colour, spinners and progress bars only when stderr is
  a TTY; `NO_COLOR` disables colour. A redirected run should produce clean text.
- **Exit code 0 with output that was never produced is a trap worth naming**: a
  subprocess that fails to spawn, or whose output is piped and then lost, can leave
  a "successful" run behind. Assert on the *content* the caller needs, and check the
  child's status explicitly.

## Errors

- Use the same error types as any other Rust code: `std::error::Error`, carrying
  the offending value, never `String`.
- **One top-level place prints the error** and maps it to an exit code — either
  return `Result` from `main` (which prints `Debug`) or match it and print a
  friendly form. Do not let `Debug` output be the user's only diagnostic for an
  expected failure; expected failures deserve a sentence.
- **A failure that leaves a partial result says what it left behind.** "Wrote 3 of
  10 files, then failed on `b.rs`" is actionable; "error" is not.

## Structure

- **`main` reads args, then calls `run()`.** Keep `main` free of logic — it is the
  only part that needs a process to test.
- **One concern per subcommand**, and a subcommand that shares a parser fragment
  shares the struct, not a copy of the flags.
- **Config precedence is explicit and documented**: flag > environment variable >
  config file > default. Print the resolved value under a `--verbose` or `-v` flag
  when the precedence bites.
- **Destructive operations confirm, or require an explicit flag.** `--force` exists
  so that the default path is safe.

## Tests

- **Test `run()` with parsed args**, not by spawning the binary, wherever possible.
- **Assert on exit codes** for the failure paths — a test that only checks the
  message will pass while the code regresses to `0`.
- **Assert stdout and stderr separately**, so a progress line moving to stdout
  fails the suite rather than a downstream pipe.
