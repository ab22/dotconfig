# Code Review — Rust (Axum + sqlx)

The Rust adaptation of the five review axes, consumed by the
`code-review-and-quality` skill.

**Precedence.** The Rust conventions are the rule files —
`~/.agents/rules/rust/RUST.md` and `rust/CODE_REVIEW.md` — and they win over this
file where the two differ; the repository's own `.agents/RUST.md` wins over both.
This file adds the Axum/sqlx review depth. Sections marked **(if the repo uses
this seam)** describe one common architecture, not a universal rule: apply them
only when the repo's `.agents/RUST.md` declares that shape, and never flag their
absence as a defect.

## Correctness

- **No `unwrap()`, `expect()` or `panic!` on a production path.** Return
  `Result` with a typed error (`thiserror` or hand-written). A repository returns
  the **domain** error, never the driver's (`rust/RUST.md`, *Keep the domain
  format-free*); `anyhow` is acceptable only where nothing downstream branches on
  the variant, and it never reaches the response (see `security-rust.md`).
- **A public async trait method used across tasks needs a `Send` future.** A bare
  `async fn` in a trait does not promise one; write
  `fn m(…) -> impl Future<Output = Result<T>> + Send` (capture owned values, return
  `async move { … }`) where callers spawn it. Synchronous methods stay plain `fn`.
- **(if the repo uses this seam)** Traits carry `#[automock]` and implementations
  are injected through `new(…)` constructors.
- **Never block in an async context** (`tokio::task::spawn_blocking` if you must),
  and never hold a lock across an `.await`.

## Error mapping — a defect, not a nit

- **Every domain error type and every variant needs an explicit arm** in the HTTP
  mapping. An unmapped variant silently becomes **`500`**.
- The match must stay **exhaustive**, so a new variant is a *compile error* rather
  than a silent `500`. A non-exhaustive match is a regression.
- Statuses: **`422`** for a malformed value (a domain `ValidationError` — the only
  carrier once rules live on the domain inputs), **`409`** for a state conflict, **`404`**
  for a missing record.
- Every new variant also gets a case in the **table-driven mapping test**.
- Precedent: a `ValidationError::InvalidUUID` variant once fell through to `500`.
  It was fixed by adding the arm *and* a regression test — both are required.

## Transaction seams (if the repo uses this seam)

- **Repository** methods take `&mut U where U: UnitOfWork` — required and generic.
- **Service** methods and use-case `execute` take an **optional** uow:
  `None` → open their own connection/transaction; `Some(&mut uow)` → join the
  caller's, so several operations commit or roll back together.
- A service **must never commit or roll back a unit of work it does not own**.
  Resolve both paths through the shared helpers (`uow_or_conn` / `uow_or_tx`
  returning a joined-or-standalone value, committing only when standalone).
- **The finding:** a service method that always opens its own connection cannot
  participate in a use case's transaction, so composition silently loses
  atomicity. Do not invent a third resolution shape locally.

## Input mapping

Two hops, each a standard conversion:

1. `impl From<XRequest> for XInput` at the HTTP boundary.
2. `impl TryFrom<XInput> for DomainModel` for create/list.

- **Flag** a hand-rolled `to_*` / `into_*` method that could be a `TryFrom`.
- **Accept** a named method when the conversion needs context a trait cannot take
  — typically a **patch that needs the previous state**:
  `Patch<X>Input::apply_to(self, prev)`. Multiple conversion strategies
  (`to_strict()` / `to_lenient()`) justify one too.
- Value objects keep their own `TryFrom` returning the domain error.
- **Mapping tests live beside the mapping**, not in the service.

## Closed-set string enums and boundaries

Owned by the rule files — review against them, do not re-derive here:
`rust/RUST.md` (*Shape of a closed-set string enum*, *One table of strings,
only*) and `gates/VALIDATION.md` (absent vs `null` vs `""`). The sqlx-specific
point they imply: a **derived `sqlx::Type` on a domain enum** is a third name
mapping and turns an unknown stored value into a `ColumnDecode` error instead of
the domain error — store the code as `TEXT`, `.parse()` on read, `as_str()` on
bind.

## Architecture (if the repo uses this seam)

- **Service vs. use case is decided by scope, not by collaborator count.**
  - *Service* — one primary model, several verb methods
    (`create` / `get_by_id` / `list` / `patch` / `delete`). It **may** inject
    several repositories and other services; *"it uses two repositories" is not a
    reason to write a use case.*
  - *Use case* — a **named business action** (named after the action, not the
    entity), **exactly one `execute`**, owns the transaction boundary and any
    cross-aggregate invariant.
- Handlers are **standalone functions** generic over the app state, returning
  `impl Future<Output = Response> + Send`. Read the authenticated principal from
  the auth extension; **map every error through `process_error`** and never return
  a raw error from a handler.
- **Authorization is a ladder**: authorize → resolve the organization → require a
  role. The organization id comes from the authenticated token, **never trusted
  from the request body**.
- Annotate services and handlers with `#[instrument(skip(…))]` so secrets and
  bodies stay out of traces.
- Refactor smell: does this reduce the concepts a reader must hold, or just
  relocate them?

## Performance

- **N+1 queries** on list endpoints — one query per row instead of one join or
  one `IN (…)`. This is the most common real defect.
- **Missing pagination** on a list endpoint; unbounded fetches into a `Vec`.
- Prefer the compile-time-checked `sqlx::query_as!` macro for plain queries; use
  the non-macro form only for dynamic SQL or `json`/`jsonb` columns.
- An offline query cache must be regenerated after any SQL or migration change,
  or the build fails on a fresh checkout.

## Security

- **Parameterized SQL only.** No string-built queries, ever.
- Authorization checked per organization on every org-scoped route.
- Secrets come from the environment, are never committed, and are never logged.
- Data from external sources is validated at the boundary before use.

## Tests

- Unit behaviour: colocated `#[cfg(test)] mod tests`.
- Integration: the repo's integration suite, marked serial where it shares a
  database, using the repo's own connection/transaction helpers.
- Table-driven tests for error mapping and for every parser.
- Every new error variant gets a mapping case.
- A bug fix arrives with a **failing-first** regression test.

## Red flags

- An error type or variant with no mapping arm, or a non-exhaustive mapping match.
- `unwrap()` / `expect()` / `panic!` on a production path.
- Where the repo uses a unit-of-work seam: a service method with no optional
  unit of work (it cannot join a transaction).
- A hand-rolled conversion that could be a `TryFrom`, or two tables of strings
  that can drift (`as_str` plus a serde rename with no test pinning them — see
  `rust/RUST.md`).
- `rename_all` used for an arbitrary code, or a case-insensitive requirement
  answered with `alias`.
- A required input defaulted instead of rejected.
- An org-scoped handler that reads the organization id from the body.
