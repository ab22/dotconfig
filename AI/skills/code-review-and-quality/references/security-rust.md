# Security & Hardening — Rust (Axum + sqlx)

The Rust adaptation of the security axis, consumed by the `code-review-and-quality`
skill. Invoke it through `.agents/SECURITY.md`, which defines *when* it applies.

This file is **repo-agnostic**: it names the defects a reviewer of *any*
Rust/Axum/sqlx service must look for. Each repository's own `.agents/RUST.md`
carries its concrete wiring — its error enums, its privilege ladder, its bucket
layout — and **wins over this file** where they differ.

Three files, read together:

| File | What it covers |
| --- | --- |
| `references/security-checklist.md` | the language-agnostic checklist — OWASP-shaped, applies to any stack |
| `references/code-review-rust.md` | the five review axes adapted to Rust |
| **this file** | the Rust-specific depth on the security axis |

## Start with the trust boundary

Controls bolted on without a threat model are guesses. Before hardening anything,
spend five minutes naming:

- **Where untrusted data enters.** HTTP bodies, path and query parameters, headers,
  file uploads, webhooks, third-party APIs — *and* the local values that look
  internal because the OS handed them over: another process's environment, a
  filename on a shared volume, a path in a job payload. Trust follows who *wrote* a
  value, not which channel delivered it.
- **What is worth stealing or breaking.** Credentials, personal data, admin
  actions, money.
- **Which boundary a change touches.** A change that crosses one gets the security
  axis first, before readability or performance.

Write **abuse cases next to use cases** — "how would I misuse this?" — and make the
first one a test. A feature whose trust boundaries cannot be named is not ready to
be secured, and this is a design finding, not a code finding.

## SQL and data access

- **Every value is bound.** No request value ever reaches the database as SQL text.
- **The macro is not what makes it safe.** `query!` / `query_as!` are
  compile-time *checked* against a live DB or the offline `.sqlx` cache; `query()` /
  `query_as()` are the runtime form. Both are equally injection-safe, because the
  protection comes from bind parameters being sent separately from the statement —
  sqlx does **not** substitute placeholders client-side. Choose the macro for type
  checking, not for safety, and do not report the runtime form as a defect on its
  own.
- **`format!` into SQL is a defect when the interpolated fragment is
  attacker-influenced.** It is acceptable only when every fragment is a hard-coded
  constant, an allowlisted identifier, or a generated `$1, $2` placeholder list.
- **Identifiers cannot be bound.** `ORDER BY $1` is a syntax error, not a bound
  column — so a request-supplied sort key, column or direction maps through a
  closed enum or a `match` to a `&'static str`. Interpolating the request field
  directly is the defect this rule exists for.
- **`QueryBuilder::push` writes raw SQL; `push_bind` binds.** Its own docs warn that
  `push` performs no sanitization. `build()` is explicitly *unchecked* against the
  schema, so a builder path silently loses what the macro gave you.

```rust
// defect: request value becomes SQL text
let sql = format!("SELECT * FROM orgs WHERE name LIKE '%{q}%'");
// defect: request value becomes an identifier
let sql = format!("SELECT * FROM orgs ORDER BY {sort_by} {dir}");

// ok: allowlisted identifier, value bound
let col = match req.sort_by.as_str() {
    "name" => "name", "created_at" => "created_at", _ => "id",
};
sqlx::query_as::<_, Org>(&format!("SELECT * FROM orgs ORDER BY {col} LIMIT $1"))
    .bind(limit)
    .fetch_all(&mut *conn)
    .await?;
```

Also a finding: a `.sqlx/` cache committed but not regenerated after a migration
change — CI then verifies queries against stale SQL.

## Authentication

- **Hash with a deliberately slow, salted algorithm**, and take the cost from
  configuration, never a literal that can drift down to a test value.
  `bcrypt::DEFAULT_COST` is 12, `MIN_COST` is 4; a cost of 4 in a real code path is a
  defect. Argon2id is the current OWASP first choice, with bcrypt as the legacy
  option and a minimum work factor of 10.
- **bcrypt truncates the password at 72 bytes, silently.** No error, no opt-out.
  Two passwords sharing their first 72 bytes hash identically. A byte-length cap in
  the validator is therefore a **security control**, not cosmetics — and it must
  count *bytes*, not `chars().count()`.
- **`bcrypt::verify` already compares in constant time** internally. Do not
  hand-roll a comparison, and do not "optimise" by fetching the row first and
  comparing hashes with `==`.
- **Verify even when the account does not exist.** An early return on an unknown
  user is a user-enumeration oracle: it is both a different response and a
  measurably faster one. Verify against a dummy hash, then return one generic
  failure for wrong-password, no-such-account and locked-account alike.
- Do not treat a `verify` `Err` as "wrong password" without distinguishing a
  malformed stored hash — that hides database corruption.

```rust
// defect: no length cap anywhere between the request and the hash
pub struct LoginRequest { pub email: String, pub password: String }

// defect: the user-existence branch
if user.is_none() { return Err(AppError::InvalidCredentials); }
```

## Sessions and tokens

- **Generate from the OS CSPRNG**, with at least 128 bits of entropy — 32 random
  bytes is the conventional choice. A token built from a user id, a timestamp, a
  `u64`, or any userspace PRNG is a defect.
- **Store only a hash of the token at rest.** A bearer token in a table is
  impersonation for whoever reads the table. SHA-256 is the right choice here —
  unlike a password, the token is already high-entropy uniform randomness, there is
  nothing to brute-force, and a slow KDF cannot be paid on every request.
- **Compare secrets in constant time.** `==` on `String`/`&str`/`[u8]` is `memcmp`
  and may return on the first differing byte. Use `subtle::ConstantTimeEq` for
  tokens, invite and password-reset codes, OTPs, and HMACs. Note its slice impl
  short-circuits on differing *lengths*, so compare fixed-width values (decode or
  hash both sides first).
- **Give every token an explicit expiry** — absolute, and ideally idle — and
  enforce it in the lookup query rather than in Rust after the fetch. Invalidate
  sessions on password change.

```rust
// defect
let token = format!("{}-{}", user.id, Utc::now().timestamp());
let token = format!("{:x}", rand::random::<u64>());   // 64 bits
if provided_token == stored_token { /* authenticated */ }
```

## Authorization

- **Authentication is not authorization.** *Who you are* is established once;
  *whether you may act on this object* is asserted per endpoint, per object.
  Broken object-level authorization is the top API risk, and comparing the caller's
  own id against a request id is not sufficient — it addresses only the simplest
  case.
- **Put the tenant predicate in the SQL, not only in Rust.** A query that cannot
  return another organization's row is structurally correct; a handler that fetches
  by id and then compares `row.org_id == user.org_id` is one early return away from
  being wrong.
- **Protection must be the default.** A middleware applied per route is opt-in, so
  a new route nobody wrapped is silently unprotected and nothing fails to compile.
  Prefer splitting public from protected routers, or — stronger — make the proof a
  type: a `FromRequestParts` extractor that fails `401`, so a handler that forgets
  it cannot read the principal at all.
- **Never read privilege from the request.** A role, org id, or `is_admin` flag in a
  body is client-asserted.
- **Do not distinguish "not yours" from "does not exist"** with `403` vs `404` —
  that is a resource-enumeration oracle. Return the same `404`.

```rust
// defect: authenticated, never authorized
let inv = s.invoices.find_by_id(id).await?;
Ok(Json(inv))

// ok: the principal is a type, and the query carries the tenant
let inv = s.invoices.find_for_org(id, user.org_id()).await?
    .ok_or(AppError::NotFound)?;
```

Every diff that adds or changes a route should be answerable with: *which layer or
extractor authorizes this, and is there a negative test for another tenant's id?*

## Input boundaries

- **Deserialize into a request DTO, never into the domain entity.** The danger is
  the fields the entity legitimately has — `role`, `org_id`, `verified`, `price` —
  being settable by a client that simply adds them to the JSON.
  `#[serde(deny_unknown_fields)]` turns that from a silent no-op into a `422`; note
  it cannot be combined with `flatten`.
- **Validate at the boundary**, then let the domain type make the invalid state
  unrepresentable (`#[serde(try_from = "RawDto")]`, or a `TryFrom` into the model).
- **Absence, `null` and `""` are three different states.** In a PATCH DTO,
  `Option<T>` cannot tell "field absent" from "field explicitly null" — so an
  omitted `role` must not mean "clear the role".
- **Bound the body.** Axum rejects bodies over 2 MB by default for `Bytes` and the
  extractors built on it (`Json`, `Form`, `String`) — but an extractor that consumes
  `Body` directly with `poll_frame` gets **no** limit, and `DefaultBodyLimit` is
  local to extractors that opt in. A global `RequestBodyLimitLayer` is the backstop,
  and `DefaultBodyLimit::disable()` without a replacement is a defect.

## Uploads and presigned URLs

A presigned URL is a **bearer capability to write one key**, minted with the
application's own permissions. Everything the client controls must be pushed into
the signature rather than trusted when the upload lands.

- **The server chooses the key.** Generate it from the authenticated principal plus
  a fresh UUID, and take the extension from the *validated* type — never from the
  client's filename. A client-supplied `key`, `prefix` or `bucket` is a defect, and
  a concatenated prefix lets `../` escape it.
- **Sign `Content-Type` and `Content-Length`** by setting them on the presigned
  request. Unsigned, they are ordinary headers the client picks: a declared image
  that is really HTML becomes stored XSS when served from your origin, and an
  unbounded length turns the URL into a write-anything capability.
- **Keep the TTL short** — minutes, not hours. A leaked URL from browser history, a
  proxy log or a `Referer` header is exploitable for exactly as long as it lives.
- **The declared MIME type is not evidence.** It is trivially spoofed, and magic-byte
  sniffing alone is routinely bypassed; use both, as complements.
- **Verify after the fact, before the object is usable.** The request-time checks
  cannot see what bytes actually landed. Finalize must `HeadObject` (existence, real
  size, stored type) and read the first few hundred bytes for magic bytes, then
  either mark the row verified or delete the object. A finalize endpoint that
  persists the client's asserted `size` and `content_type` without touching S3 is
  the defect this rule exists for.

```rust
// defect: client-chosen key, nothing signed, client's word accepted
let key = format!("uploads/{}", req.filename);
let url = client.put_object().bucket(&b).key(&key).presigned(ttl).await?;
db.set_image(req.key, req.content_type, req.size).await?;
```

## Secrets and configuration

- **Wrap every secret in a `secrecy` type** and reach it only through
  `ExposeSecret` at the point of use, so it cannot be `Debug`-printed and is zeroized
  on drop. `SecretBox`'s `Debug` redacts *without* requiring the inner type to be
  `Debug`; its `Clone` and `Serialize` impls are gated behind explicit marker traits,
  which is the point — do not reach for `.expose_secret()` inside a `Debug` impl.
  (The API shape differs between `secrecy` 0.8/0.9 and 0.10; check the pinned
  version before quoting a type name.)
- **Never derive `Debug` on a config or credential struct by reflex.** It is the
  enabler for the logging defects below.
- **Environment variables are transport, not storage.** `env::var` copies the value
  while the original stays readable in the process environment for its lifetime and
  is inherited by children. Read once at startup into a secret type; never
  `set_var` a secret, never log the whole config.
- **TRACE on an AWS SDK is a credential-leak switch.** The SDKs have historically
  logged signing material at TRACE (CVE-2023-30610 in `aws-sigv4`); a per-target
  filter keeping AWS crates at `info` is the durable control, independent of the
  pinned version.

## Logs, errors and information disclosure

- **`#[instrument]` records every argument by default**, using `Display` for
  tracing primitives and **`Debug` for everything else**. An instrumented handler
  that takes a login request therefore logs the password — with no logging statement
  anywhere in the diff. Use `#[instrument(skip(…))]` / `skip_all` plus explicit
  `fields(…)`. A useful tell: if the fix required adding `#[derive(Debug)]` to a
  credential type, the design is wrong.
- **`sqlx::Error::Database` carries the driver's message**, which names constraints,
  tables and columns. A `ColumnNotFound` names the column. Returning
  `e.to_string()` to a client is schema disclosure; string-matching on
  `db.message().contains("duplicate key")` to pick a status is both a leak and a
  fragile control. Map on the typed error instead.
- **`anyhow` must not reach the response.** It erases the type, so the central
  mapper can no longer choose a correct `404`/`409` and falls back to a blanket
  `500`. Let `anyhow` propagate *up to* the boundary; convert through the typed enum.
- **Never log request bodies, `Authorization` headers, tokens, passwords or
  personal data** — including truncated tokens, which are still credentials. Log
  ids, not emails. Sanitize CR/LF in attacker-influenced fields to prevent log
  injection.

## Panics, overflow and denial of service

- **Check the release profile before reasoning about any of this.** With
  `panic = "abort"` — common for a deployed binary — unwinding never happens, so
  `catch_unwind`, `Drop` cleanup and any panic-catching middleware cannot turn a
  panic into a `500`. A single `unwrap()` on request-derived input becomes a **full
  service outage** rather than one failed request. Any "we would catch it at the
  edge" assumption is false in that build.
- **`overflow-checks` defaults to `false` in release.** Arithmetic that panics
  loudly under `cargo test` **wraps silently** in production. The question is not
  only "can this panic?" but "can this wrap, and does anything downstream trust the
  result?" — which is worse wherever a length check or a cost calculation is
  involved.
- **No `unwrap()` / `expect()` / `panic!` / unchecked indexing or slicing on a
  request path.** `.unwrap()` is acceptable only where the invariant is local and
  documented — a `const` array, a literal regex, a static header value. Everything
  else gets `?`. Clippy: `unwrap_used`, `expect_used`, `indexing_slicing`,
  `arithmetic_side_effects`, `panic_in_result_fn`.
- **Watch for amplifiers.** A deliberately slow hash makes login a CPU amplifier;
  a JSON body that deserializes into deeply nested or unbounded collections is a
  memory amplifier even under the size limit.

## Browser-facing hardening

- **Never combine a wildcard or reflected origin with credentials.** `tower-http`'s
  `CorsLayer::very_permissive()` reflects the request origin *and* allows
  credentials — any site can then make authenticated cross-origin requests as the
  logged-in user and read the responses. `permissive()` is origin-`Any` without
  credentials: usually still wrong for an authenticated API, but not the
  account-takeover variant. **These two look alike in a diff and are not alike.**
  Hand-written `.allow_origin(Any).allow_credentials(true)` is the same defect, and
  a suffix predicate (`ends_with("example.com")`) matches `evil-example.com`.
- **Add the security headers.** `tower-http` ships no secure-headers bundle, so they
  are assembled one `SetResponseHeaderLayer` at a time: HSTS,
  `X-Content-Type-Options: nosniff`, `X-Frame-Options` plus CSP `frame-ancestors`,
  and `Referrer-Policy`.
- **`Referrer-Policy` is not filler on a service that hands out presigned URLs.** A
  presigned URL in a query string is a bearer capability, and the browser's default
  `Referer` behaviour can leak the full URL to third-party origins.
  `strict-origin-when-cross-origin` or `no-referrer`.
- **Layer order matters**: `Router::layer` applies only to routes added before it.

## Throttling authentication

- **Rate-limit by IP *and* by account** on every low-entropy flow: login, password
  reset, invite acceptance, OTP verification. Per-IP alone does nothing against
  password spraying; account lockout alone is a denial-of-service against a known
  username.
- **A limiter keyed on a client-supplied header is a no-op** — rotating
  `X-Forwarded-For` defeats it. The proxy must overwrite the header, and the app must
  key on the real peer address.
- **Build the limiter config once and share it.** A configured-per-route or
  per-request limiter silently multiplies the effective quota. Match the governor
  crate's major to your axum major, or you get a second axum in the tree or a build
  failure.
- Return a generic failure for every authentication outcome, with comparable timing,
  and monitor the throttle rather than silently locking accounts.

## Dependencies and supply chain

- **Commit the lockfile** for a binary crate — it is the reproducible resolution, and
  a diff that changes it without a manifest change is a dependency change deserving
  the same review as code.
- **Run `cargo-deny` (advisories, licences, bans, sources) and `cargo-audit` as
  gates**, and `cargo-vet` where you consume third-party audits.
- **Triage by version *range* and reachability, never by title.** Read the
  advisory's own `Patched` and `Unaffected` fields, then ask whether the affected
  function is reachable in this binary. Two worked examples of getting this right:
  - `bcrypt` carries RUSTSEC-2026-0199, a panic on a non-ASCII hash string — but its
    own metadata says `Unaffected: <0.19.0`, so a service on the 0.15 line is **not**
    affected, and raising it is a false finding.
  - `rand` carries RUSTSEC-2026-0097 (unsoundness with a custom `log` logger and
    `thread_rng`) against `<0.10.0, >=0.7.0` — but the 0.8 line is patched at
    `>=0.8.6`, so `cargo update -p rand` resolves it. The narrow conditions still
    matter when deciding urgency.
- An advisory you cannot `cargo update` past needs a **design answer** and a written
  reason with a review date — not a blanket `ignore`.

## Cryptography and unsafe

- **Do not assemble a construction.** The realistic Rust failure is not a
  hand-written AES but `sha256(password + salt)`, a truncated HMAC used as a token,
  or a KDF made of repeated hashing. If a diff introduces cryptographic
  *composition* — what feeds into what, in which order, under which key — it needs a
  named standard construction or a crate that offers it directly.
- **Never reuse a nonce or IV.** Nonce reuse under GCM or ChaCha20-Poly1305 is
  catastrophic. A counter that restarts per process, or a random 96-bit nonce
  generated beyond its safe bound under one key, is a finding. Use the AEAD crates,
  which do not expose ECB.
- **Let `rustls` pick.** Its main API cannot disable certificate verification —
  the strongest single argument for it over a native-TLS binding, where a
  `danger_accept_invalid_certs`-equivalent can be reachable from configuration.
  Never enable a TLS key log in production.
- **`#![forbid(unsafe_code)]` at the crate root** makes unsafe unrepresentable in
  your own code; `cargo-geiger` shows where it actually lives, which is the
  dependency tree.

## Red flags

- A request value interpolated into SQL text, or into an identifier position.
- A handler that authenticates but never checks the object belongs to the caller; a
  route that escaped the auth layer; a tenant predicate missing from the query.
- A `403` that distinguishes "not yours" from "does not exist".
- An `unwrap()` / `expect()` / indexing on request-derived data in a build with
  `panic = "abort"`; arithmetic on request-derived numbers under release wrapping.
- A presigned URL whose key, content type or length the client chose, or a finalize
  step that trusts the client instead of reading S3.
- `#[instrument]` on a handler taking credentials or a body; a logged token or
  body; an error body containing `sqlx` text.
- A secret compared with `==`; a token generated from anything but the OS CSPRNG;
  a token stored in plaintext.
- `very_permissive()` or `Any` + credentials; no security headers; no throttling on
  login.
- A `Cargo.lock` change with no manifest change; an advisory ignored by title, or
  without a reason and a review date.
