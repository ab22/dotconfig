# Rust conventions (shared)

Cross-project baseline for Rust repositories that vendor these modules.
Each repo's own `.agents/RUST.md` holds its concrete wiring (error types, HTTP
mapping, database layer) and **wins over this file** where they differ.

## Prefer enums over raw strings

A value that is a small fixed set of strings — a currency, a status, a kind, a
code — is a **closed-set enum**, never a `String`. Keep raw strings out of domain
models and parse once, at the boundary. This is "parse, don't validate"
(<https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/>): parsing
produces a value that *cannot* be invalid, so no downstream code re-checks it.
Validating a `String` and discarding the result is the "shotgun parsing" failure
mode — the check and the use drift apart.

## Shape of a closed-set string enum

- The **variant set is the supported set**. There is no parallel allowlist of
  strings that can drift from the type.
- `pub const ALL: &'static [Self]` for iteration.
- `pub const fn as_str(self) -> &'static str` — the **single source of truth**
  for the wire, database and display form.
- `impl FromStr` — the real parser, so `str::parse()` works. Implement it rather
  than `TryFrom<&str>` alone: `FromStr` is what `.parse()` uses, and Clippy now
  steers parsing types toward it
  (<https://github.com/rust-lang/rust-clippy/issues/14522>). (A common belief
  that the std docs advise *against* `FromStr` in favour of `TryFrom<&str>` is
  **not** in the std docs or source — do not repeat it.)
- `impl TryFrom<&str>` and `impl TryFrom<String>` — one-line delegations to
  `from_str`, for generic code that only bounds on `TryFrom`. Whether the two
  traits differ semantically is contested upstream; delegating instead of
  re-implementing the match makes the question moot.
- `impl Display` writing `as_str()`. The std docs explicitly call it surprising
  when `Display` output cannot be parsed back with `FromStr`, so they must
  round-trip.
- Tests pin the invariants: every code round-trips through `as_str`/`FromStr`,
  the form is validated (e.g. 3 uppercase ASCII letters), and no duplicate
  entries exist in `ALL`.

## One table of strings, only

Serialization must delegate to `as_str()`/`FromStr` through **hand-written**
`Serialize`/`Deserialize` impls.

- Do **not** put a name attribute (`#[serde(rename = "…")]`, `#[serde(rename_all = "…")]`,
  `#[sqlx(rename_all = "…")]`) on each variant: every one is a second copy of the
  code, free to drift from `as_str()`. Three parallel tables (`as_str` + serde +
  sqlx) with no test tying them together is the classic defect.
- `rename_all` can only case-*transform* a variant name; it cannot express an
  arbitrary code (`HNL`, `application/pdf`). Neither `rename_all` nor `alias`
  provides **case-insensitive** matching — that needs a delegating `Deserialize`.
- `Serialize` should call `serializer.serialize_str(self.as_str())`. A derived
  form, or `#[serde(into = "String")]`, allocates a `String` per value.

If a repo does keep name attributes, it must add a test asserting the serde form
equals `as_str()` for every variant.

## Errors

Parse failures return a real error type implementing `std::error::Error` —
never `String`, `&'static str`, or `()`
(<https://rust-lang.github.io/api-guidelines/interoperability.html>). Carry the
offending value so the message is actionable.

A small dedicated error type per parseable value, or one shared domain error enum
with a variant per type, are both defensible; pick one per repo and be
consistent. Whatever the choice, the HTTP layer must map it explicitly:

- an error type or variant with **no mapping arm silently becomes `500`** — that
  is a defect, not a nit. Match exhaustively so a new variant is a compile error,
  and cover each variant in a table-driven test of the error mapping.
- Prefer `422` for a malformed value, `409` for a state conflict, `404` for a
  missing record.

## Case and whitespace policy

Decide it, document it on the parser, and test it. Case-insensitive, trimming
parsing is safe **only** because the parsed result is always the canonical form —
so leniency cannot let a non-canonical value reach storage.
