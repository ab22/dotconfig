---
description: Rust for HTTP APIs and services
---

> **Read this from `rust/RUST.md` when the Rust code is an HTTP service or server.**

# Rust for HTTP APIs and services

Layer on top of the `rust/RUST.md` — the enum, domain and error rules there all
apply. This reference adds the transport concerns: layering, request/response
shapes, and the error → HTTP mapping.

**If the service is async — it almost certainly is — read [`TOKIO.md`](TOKIO.md)
too.** Blocking a worker thread, a timeout that never fires and a shutdown that
drops in-flight work are transport defects, and a single-request test shows none of
them.

**If the change touches authentication, authorization, new input or uploads, read
[`../gates/SECURITY.md`](../gates/SECURITY.md) as well.** An HTTP service is where
every trust boundary in the system actually sits.

A repo's own `.agents/RUST.md` names its concrete wiring (which framework, which
error enum, which status codes it already returns). **That wins over this file.**

## Layering

```
transport (HTTP)  →  use case / service  →  domain  ←  repository (infrastructure)
```

Dependencies point **inward**. The transport knows about HTTP; the domain knows
about neither HTTP nor the database. The repository trait is declared where the
use case needs it and implemented in infrastructure.

The practical test: if you deleted every transport file, the domain and its tests
would still compile. If they would not, a format leaked inward.

## Requests and responses are DTOs

- **Deserialize into a request DTO**, then `From`/`TryFrom` into the domain. Do not
  deserialize straight into a domain type: that is how a serde derive ends up on
  the entity.
- **Serialize from a response DTO**, converted from the domain on the way out.
- The DTO owns the wire spelling — `#[serde(rename_all = "…")]` belongs there, on
  a type of its own, not on the domain enum.
- **A field the client may omit is `Option<T>` on the request DTO**, and the
  conversion decides what absence means. See the `gates/VALIDATION.md` file for the
  absent-vs-null rules; the shorthand is: omit = leave alone, `null` = clear,
  `""` on a required field = reject.

## Mapping errors to responses

The domain classifies the failure; the transport chooses the status code. That
mapping belongs in one place — an `impl IntoResponse` / `From<DomainError>` / a
single `match` at the edge — not scattered across handlers.

- **An error with no mapping arm silently becomes `500`.** That is a defect, not a
  nit. Match exhaustively so a new domain variant is a compile error, and cover
  every variant with a table-driven test of the mapping.
- **Choose the code deliberately:**
  - `422` for a value that is well-formed but invalid (a malformed code, a
    failed invariant);
  - `409` for a state conflict (already exists, version mismatch);
  - `404` for a missing record;
  - `401` / `403` for authentication vs authorization — never `404` to hide one
    unless the resource's existence is itself sensitive, and then say so;
  - `400` for a request that could not be parsed at all;
  - `500` only for a genuinely unexpected failure — never as the default arm.
- **The response body carries an actionable message and nothing internal.** No
  driver text, no file paths, no SQL, no stack traces. Log the detail; return the
  sanitized message.
- **Log once, at the edge.** A global catcher (middleware or the top-level handler)
  owns logging and tracing context. A handler that logs and returns an error the
  edge will also log produces two records of one failure.

## Handlers stay thin

A handler extracts, calls one use case, and maps the result. Business rules in a
handler cannot be reused by a job, a CLI, or a second endpoint — and they cannot be
tested without an HTTP harness.

- No SQL in a handler. No `if` on a domain state machine in a handler.
- **Never return the entity directly.** A response DTO exists so the wire shape can
  change without touching the domain — and so a field added to the entity is not
  published by accident.
- **Paginate collections from the start.** A list endpoint that returns everything
  works until it does not, and retro-fitting pagination is a breaking change.
- **State the status code explicitly** rather than relying on a default; the
  default is how a created resource answers `200`.

## Tests

- **The mapping table is a test.** One case per domain variant, asserting the
  status code and that the message does not leak internals.
- **The boundary cases are tests**: absent key vs explicit `null` vs `""` vs
  whitespace-only, for every field the contract distinguishes. Table-driven is the
  cheapest form.
- **Test the use case without HTTP** where the logic lives there — the point of the
  layering is that this is possible.
- Where an end-to-end suite is the repo's contract, keep it green and treat it as
  the specification.
