---
description: Rust conventions — prefer closed-set enums over raw strings, one table of strings as the single source of truth, a format-free domain with dependencies pointing inward, real error types with no silent default arm, and the dependency/lockfile policy. Routes to the task files for an HTTP service, a CLI, testing, and review.
---

> **Read this when working in Rust: writing, changing or reviewing any `.rs`, `Cargo.toml` or `Cargo.lock`.**

# Rust conventions

This is the **floor**: it applies to every Rust project. It is also a **router** —
read it first, then follow the row that matches the work.

| The code is… | Read next |
| --- | --- |
| an HTTP service or any long-running server | `rust/API_HTTP.md` — layering, error → HTTP mapping, status codes |
| a command-line tool | `rust/CLI.md` — argument parsing, exit codes, stdout/stderr discipline |
| **async, or using Tokio** | `rust/TOKIO.md` — never block a worker, spawn with a purpose, channels, timeouts, shutdown |
| a library crate or shared code, neither of the above | nothing further from this table |
| **being tested, or written test-first** | `rust/TDD.md` — where tests live, table-driven cases, the invariants worth a round-trip test |
| **being reviewed** | `rust/CODE_REVIEW.md` — the Rust defects a language-agnostic review walks past |

These are **task routers, not alternatives** to one another: an async service under
review reads `rust/API_HTTP.md`, `rust/TOKIO.md` **and** `rust/CODE_REVIEW.md`.
Each task file names the general rule it refines, and you read that general file
too.

A repo's own `.agents/RUST.md` carries its concrete wiring — its error types, its
HTTP mapping, its database layer — and **wins over this file** where they differ.

## Prefer enums over raw strings

A value that is a small fixed set of strings — a currency, a status, a kind, a code
— is a **closed-set enum**, never a `String`. Keep raw strings out of domain models
and parse once, at the boundary. This is "parse, don't validate"
(<https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/>): parsing
produces a value that *cannot* be invalid, so no downstream code re-checks it.
Validating a `String` and discarding the result is the "shotgun parsing" failure
mode — the check and the use drift apart.

## Shape of a closed-set string enum

- The **variant set is the supported set**. There is no parallel allowlist of
  strings that can drift from the type.
- `pub const ALL: &'static [Self]` for iteration.
- `pub const fn as_str(self) -> &'static str` — the **single source of truth** for
  the wire, database and display form.
- `impl FromStr` — the real parser, so `str::parse()` works. Implement it rather
  than `TryFrom<&str>` alone: `FromStr` is what `.parse()` uses, and Clippy steers
  parsing types toward it (<https://github.com/rust-lang/rust-clippy/issues/14522>).
  (The common belief that the std docs advise *against* `FromStr` in favour of
  `TryFrom<&str>` is **not** in the std docs or source — do not repeat it.)
- `impl TryFrom<&str>` and `impl TryFrom<String>` — one-line delegations to
  `from_str`, for generic code that only bounds on `TryFrom`. Whether the two
  traits differ semantically is contested upstream; delegating instead of
  re-implementing the match makes the question moot.
- `impl Display` writing `as_str()`. The std docs explicitly call it surprising
  when `Display` output cannot be parsed back with `FromStr`, so they must
  round-trip.
- Tests pin the invariants: every code round-trips through `as_str`/`FromStr`, the
  form is validated (e.g. 3 uppercase ASCII letters), and `ALL` has no duplicates.
- The type itself carries **no serde and no `sqlx::Type`** — see below.

## Keep the domain format-free

A domain type describes an entity and its invariants. It does **not** know how it
is spelled on the wire or in a column, so it derives **no** `Serialize`,
`Deserialize`, `sqlx::Type` or `FromRow`.

Each layer that references the domain owns its own representation and converts:
HTTP deserializes into a request DTO then converts into the domain; the database
puts `FromRow`/`sqlx::Type` on a `Pg*` type and converts by `From` in both
directions. Anything added later — gRPC, a CLI, a queue consumer — follows the
same shape.

The format is a *per-layer* decision. One domain enum can be a native Postgres
`ENUM` in one column, a `TEXT` with a `CHECK` in another, and `snake_case` in JSON
on the wire. A derive on the entity cannot express three decisions spread across
two layers: it silently makes one layer's spelling authoritative and leaves the
others to a second, competing table of strings.

A hand-written `Deserialize` written only to decode a request body therefore
belongs to the layer that reads the body — even when the *shape* it decodes (a
three-state patch, say) is a domain concept. Keep the shape in the domain, the
decoder in the transport.

**Dependencies point inward.** The domain imports nothing from the layers around
it — not their types, and not their error types. Only an outer layer knows a
format, which is what makes the ban above hold in the first place.

- **A repository failure is a domain error, not a driver one.** The persistence
  vocabulary (`NotFound`, `Conflict`, …) is the domain's; the infrastructure layer
  converts a driver error into it at the boundary. A repository trait documents the
  domain variant, never the driver's.
- **The conversion is total.** No pass-through arm: an unmapped driver error gets
  the opaque catch-all variant rather than escaping as the driver's own type. A
  repository may inspect a driver error to turn one specific constraint into one
  specific domain error — that is the repository's job — but the result is still a
  domain error.
- **The domain classifies, the transport translates.** A use case may match
  `NotFound`; mapping that to a status code belongs to the transport, the only
  layer that knows what a `404` is. Downcasting an infrastructure error inside the
  domain is the defect this rule prevents.
- **Opaque payloads are the one exception, and they are exception-shaped.** A
  free-form JSON blob the domain cannot type (say, integration metadata) may stay
  as the serialization library's `Value`, because it asserts no format — no
  spelling, no column shape, no variant names — which is what the ban targets.
  Anything else, and any `Value` that is *read* rather than forwarded, is a design
  smell. Where a genuine exception to a layer rule is unavoidable (a port that must
  name the driver's connection type), name it in the rule, in one place: an unnamed
  exception becomes a precedent.
- **Names come from the business, not from a layer.** No
  `Request`/`Response`/`Dto`/`Payload` in the domain, and no
  `Pg`/`Row`/`Sql`/`Json`/`Column` either — those prefixes belong to the layer that
  has the format. The repository verb is `create`, not `insert`.
- **Prefer a gate to prose where the rule is mechanically checkable.** A test that
  scans the domain's sources for forbidden tokens and derives keeps a *new* file
  covered, and needs no allowlist to rot. Three properties are load-bearing, each
  learned from a real miss: match **tokens, not paths** (a brace-nested
  `use crate::{ db::X, … }` contains no `crate::db` literal); **strip comments
  first**, or prose mentioning a banned name false-positives; and **assert the walk
  found files**, because a gate that scans nothing passes vacuously.

## One table of strings, only

`as_str()` is the single source of truth for the wire, database and display form.
Every other layer **delegates** to it and keeps no second copy.

- The default delegation needs no serde at all: the layer holds a `String` and its
  `From`/`TryFrom` hop calls `parse()` inbound and `as_str()` outbound. Nothing can
  drift, because there is only one table.
- Where a layer genuinely does derive serde on a type of its own — a `Pg*` wrapper,
  a wire enum — a name attribute (`#[serde(rename = "…")]`,
  `#[serde(rename_all = "…")]`, `#[sqlx(rename_all = "…")]`) on each variant is a
  second copy of the code, and is allowed **only** alongside a test asserting the
  derived form equals `as_str()` for every variant. Without that test, hand-write
  the impls.
- `rename_all` can only case-*transform* a variant name; it cannot express an
  arbitrary code (`HNL`, `application/pdf`). Neither `rename_all` nor `alias`
  provides **case-insensitive** matching — that needs a delegating `Deserialize`.
- Hand-written `Serialize` should call `serializer.serialize_str(self.as_str())`. A
  derived form, or `#[serde(into = "String")]`, allocates a `String` per value.

## Errors

Parse failures return a real error type implementing `std::error::Error` — never
`String`, `&'static str`, or `()`
(<https://rust-lang.github.io/api-guidelines/interoperability.html>). Carry the
offending value so the message is actionable.

A small dedicated error type per parseable value, or one shared domain error enum
with a variant per type, are both defensible; pick one per repo and be consistent.

- **Errors are returned, and they are handled.** Either a global catcher logs them
  with tracing, or a specific layer processes them. An error that is silently
  discarded with `let _ =` or an ignored `Result` is a defect.
- **Never a silent `_ =>` arm.** A catch-all that turns a new variant into the
  wrong outcome is worse than a compile error. Match exhaustively.
- When you create a new error type, answer four questions before writing it:
  - Does it map to a specific outcome, or is it genuinely opaque?
  - Which one, and who decides that — this layer or an outer one?
  - Is the user-facing message clear, and does it avoid exposing internals?
  - Does the internal form carry enough to debug it?

The mapping of a domain error to a transport outcome belongs to the transport; see
`API_HTTP.md` for the HTTP case.

## Case and whitespace policy

Decide it, document it on the parser, and test it. Case-insensitive, trimming
parsing is safe **only** because the parsed result is always the canonical form —
so leniency cannot let a non-canonical value reach storage.

## Dependencies and the lockfile

A `Cargo.lock` change with no `Cargo.toml` change is still a **dependency change**,
and it is reviewed like code: the diff is read, not rubber-stamped.

- **Never hand-edit `Cargo.lock`.** Use targeted `cargo update -p <crate>` so the
  upgrade is attributable and reviewable; a blanket `cargo update` is a larger,
  separate decision.
- **A blanket update may simply fail.** When a yanked version is pinned
  transitively, cargo refuses to re-resolve it. Say so; do not hand-edit around it.
- **Triage advisories by range and reachability, never by title.** Read the
  advisory's own `Patched`/`Unaffected` fields, then ask whether the affected code
  is reachable in this build. An `Unaffected` range that covers the pin is a false
  finding; a crate absent from `cargo tree -i <crate>` is not compiled at all.
- **Every accepted advisory carries a reason and a review-by date**, kept in the
  dependency gate's config rather than as a blanket ignore. Delete an entry when
  its reason stops applying, and let an unused-ignore warning be the signal.
- **A licence allow-list is policy, not a scan result.** Adding an entry is a
  decision to ship under that licence.
- **Keep the dependency scan in the extended gate, not the default one.** An
  advisory is a triage input that needs a human decision, and the advisory database
  is fetched over the network; neither belongs in a build gate.
