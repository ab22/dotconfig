---
description: Rust-specific testing rules — read with the general tests-first gate. Where tests live, why a test function returns Result instead of unwrapping, table-driven cases, naming, property-based tests where an invariant is stated, and the repo's own test command.
---

> **Read this when the `tdd` switch is on and the code under test is Rust.**

# Rust and TDD

**Read `gates/TDD.md` first.** It owns the gate: write the
failing test, run it, confirm it fails *for the expected reason*, hand the red
output to the user and wait. Nothing here replaces that, and where the two
disagree the gate wins.

This file adds only what is specific to Rust.

## Where tests live

- **Unit tests go in the same file**, in a `#[cfg(test)] mod tests` module. They
  can reach private items, which is the point — the unit under test is the
  function, not the public API.
- **Integration tests go in `tests/`**, one file per concern, and they exercise
  the crate as a consumer would: it must compile against the public API only.
- **Doc tests are tests.** A `///` example is compiled and run by `cargo test`, so
  an example that does not compile fails the suite. That is free coverage for a
  public API, and a stale example is a real failure rather than a docs nit.
- A test helper used by several test files goes in a shared module under `tests/`
  (`tests/common/mod.rs`), not copy-pasted into each.

## Write tests that cannot panic on setup

A test function may return `Result<(), E>` and use `?`. Prefer it:

```rust
#[test]
fn rejects_blank_fixture_as_empty() -> Result<(), Box<dyn std::error::Error>> {
    let input = std::fs::read_to_string("tests/fixtures/blank.txt")?; // setup: `?`, never unwrap
    let err = parse(&input).unwrap_err();                            // the call under test
    assert!(matches!(err, ParseError::Empty { .. }));
    Ok(())
}
```

`?` and `unwrap()` inside a test are fine — a panic *is* a failed test. What is not
fine is `unwrap()` on setup that can fail, because the failure mode becomes an
opaque panic in an unrelated-looking place. `unwrap_err()`/`expect_err()` on the
call under test is the exception: there you are asserting it fails.

## Table-driven cases

Rust has no parameterised tests in the standard library. Write the table as data
and loop:

```rust
#[test]
fn parses_every_base_currency() {
    for (input, want) in [("usd", Currency::Usd), ("USD", Currency::Usd), (" usd ", Currency::Usd)] {
        assert_eq!(input.parse::<Currency>().unwrap(), want, "input: {input:?}");
    }
}

#[test]
fn rejects_invalid_currency_codes() {
    for bad in ["", "   ", "us", "usdd", "u$d", "123"] {
        assert!(bad.parse::<Currency>().is_err(), "should reject: {bad:?}");
    }
}
```

**Always put the input in the assertion message.** Without it, a table failure
tells you only that *one* of six cases broke.

The `gates/VALIDATION.md` boundary set applies to every one of these tables:
empty, whitespace-only, wrong length, wrong type/format, and one step past each
limit.

## Naming

Name the behaviour and the expectation, not the function:
`rejects_whitespace_only_code`, `round_trips_every_variant_through_as_str`.
A test named `test_parse` tells the next reader nothing about what broke.

## Invariants worth a round-trip test

The closed-set enum shape in `RUST.md` has invariants that a single example cannot
cover — write them as loops over the variant set:

- every variant round-trips: `v.as_str().parse() == Ok(v)`;
- `ALL` contains every variant exactly once (no duplicates, none missing);
- any derived serde form equals `as_str()` for every variant — this is the test
  that makes a `#[serde(rename)]` table legal.

Property-based testing (`proptest`, `quickcheck`) is worth it where the rule is a
stated invariant rather than an example: round-tripping, ordering, associativity,
"parse never panics on arbitrary input". It is not worth it for a fixed table.

## Running them

Use the repo's own command — read its `AGENTS.md` rather than assuming. The
defaults are `cargo test` for everything, `cargo test --lib` for unit tests only,
`cargo test --test <name>` for one integration file, and `cargo test <substring>`
to filter by name. **`cargo nextest run` skips doc tests** — pair it with
`cargo test --doc`. The full verify gate is in `rust/TOOLING.md`.

**Run the whole suite before calling a change done**, not just the new test: a
closed-set enum change breaks other files' tests, and that is exactly what the
suite is for.
