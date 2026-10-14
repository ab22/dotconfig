---
description: Tokio and async Rust — pick the right runtime flavour, never block a worker, spawn with a purpose, choose the right channel, put a timeout on everything external, and shut down without losing work. Read with `rust/RUST.md` for any async service or daemon.
---

> **Read this from `rust/RUST.md` when the Rust code is async, or uses Tokio directly.**

# Tokio and async Rust

Read [`RUST.md`](RUST.md) first — the enum, domain and error rules apply to every
line below. If the code is a service, read [`API_HTTP.md`](API_HTTP.md) too; its
layering and error-mapping rules are what the runtime work sits under.

Everything here is a defect class that compiles cleanly and fails under load.

## Never block a worker thread

This is the single most common async defect, and it is invisible in a test suite
that runs one request at a time.

**A blocking call inside an async task stalls every task on that worker** — not
just the one that made it. A `tokio` worker pool has one thread per core by
default; a handful of blocking calls removes the whole runtime's capacity.

| Never, inside async | Use instead |
| --- | --- |
| `std::fs::*` | `tokio::fs::*` (or `spawn_blocking` for a burst of file work) |
| `std::thread::sleep` | `tokio::time::sleep` |
| `reqwest::blocking`, a sync DB driver | the async driver |
| A CPU-bound loop over real data | `tokio::task::spawn_blocking` |
| `std::sync::Mutex` held across `.await` | `tokio::sync::Mutex`, or scope the guard so it drops first |
| A `rayon` call that waits for its result | `spawn_blocking` the wait, or restructure |

`spawn_blocking` is not a free pass: it has its own bounded pool (512 by default),
and a task that blocks for minutes exhausts it just as surely. Bound the work, not
just its placement.

**Watch for `std::sync::Mutex` specifically.** It compiles across an `.await` in
single-threaded tests and deadlocks in a real runtime, because the guard is not
`Send` and the future is pinned to one thread. If it compiles, someone disabled the
check.

## Spawn with a purpose

- **`tokio::spawn` needs a reason.** A spawned task is detached: nobody awaits it,
  so a panic in it disappears and a failure never propagates to the caller. Spawn
  when the work is genuinely independent (a background poller, a connection writer)
  — not to "make it concurrent".
- **Keep the `JoinHandle` when you need the outcome.** Dropping it discards the
  panic. `let _ = tokio::spawn(...)` is a decision that failures do not matter, so
  it needs a comment or a log line inside the task.
- **`JoinSet` for a dynamic group.** It joins and surfaces panics on `join_next()`,
  and it cancels cleanly — a `Vec<JoinHandle>` you await in a loop does neither.
- **Spawned work must be `Send + 'static`.** Fighting that with a bigger `Arc` is
  usually a signal the work belongs in the caller's task.
- **Do not spawn inside a hot loop.** One task per request is normal; one task per
  row is a scheduler problem.

## The runtime is chosen at the edge

- **`#[tokio::main]` in `main` only.** A library that starts a runtime forces its
  choice on every consumer — and a nested runtime panics with *"Cannot start a
  runtime from within a runtime"*.
- **Name the flavour deliberately.** The multi-threaded default is right for a
  server. `current_thread` is right for a test, a single-purpose CLI, or a
  deterministic ordering, and it makes "accidentally blocking" show up immediately.
- **`#[tokio::test]` defaults to `current_thread`.** A test that passes there can
  still deadlock under a real multi-threaded runtime, and vice versa for
  ordering assumptions. When concurrency is the behaviour under test, say
  `#[tokio::test(flavor = "multi_thread", worker_threads = 2)]` explicitly.
- **Set the worker count from the deployment, not from hope.** `worker_threads`
  above the CPU allocation causes contention, not throughput.

## Channels: pick by the shape of the flow

| Flow | Use |
| --- | --- |
| one producer, one consumer, in order | `mpsc` |
| many producers, one consumer | `mpsc` (clone the sender) |
| one to many, every receiver sees every message | `broadcast` |
| latest value only — the reader may miss intermediate ones | `watch` |
| one-shot reply to a specific request | `oneshot` |

- **A bounded channel is the default.** `channel(0)`/unbounded means memory grows
  with input and nothing applies backpressure — the failure shows up as an OOM
  under load, never in a test.
- **`broadcast` drops for a slow receiver and says so** (`RecvError::Lagged`).
  Handle that arm: silently skipping messages is how a watcher misses the one
  change that mattered.
- **`watch` readers see the latest value, not every value.** If every value
  matters, it is the wrong channel.
- **Close the channel instead of flagging a shutdown.** A `select!` on `recv()`
  returning `None` is cleaner than a shared `AtomicBool` that every loop polls.

## Time: every external call gets a deadline

- **`tokio::time::timeout` on anything that crosses a process boundary** — HTTP,
  the database, a queue, a socket. "It has never hung" is not a timeout policy.
- **Choose the number from the caller's budget**, not from taste: a request that
  fans out to four services needs four deadlines that fit inside its own.
- **`timeout` returns `Result<Result<T, E>, Elapsed>`.** Flattening it with `?`
  twice silently converts a timeout into the inner error type or panics on
  `unwrap` — map `Elapsed` to a real error variant (see `API_HTTP.md` for the
  status it becomes).
- **Use `tokio::time::interval` for polling, not a `loop { sleep }`** — the former
  accounts for the work's duration and does not drift.
- **Never `sleep` to wait for something that has a signal.** A fixed delay in
  production code is a race with a schedule.

## Cancellation safety

`select!` and `timeout` drop the losing future. That is safe only if the future
can be dropped at any await point without losing data or duplicating a side effect.

- **`select!` on a `recv()` is cancel-safe; a partially-read stream is not.**
  Dropping mid-read loses the bytes already consumed.
- **Do not put a non-cancel-safe future in a `select!` loop arm.** A retry loop
  that re-reads from a socket is the classic way to corrupt a protocol.
- **A cancelled future is not a failed one.** Work that must complete — a write
  that has been acknowledged, a message that has been dequeued — belongs behind
  `spawn` (which is not cancelled with the caller) or in a task that owns its own
  completion.

## Cancellation, shutdown and graceful drain

- **`tokio::select!` on a shutdown signal in every long-running loop.** A loop that
  only exits on an error is a process that needs `kill -9`.
- **`tokio::signal::ctrl_c()` for a CLI; a signal stream for a service**
  (`SIGTERM` on unix, which is what an orchestrator sends). Handle both.
- **Drain in the right order:** stop accepting new work, let in-flight work finish
  with a bounded grace period, flush the sink, then exit. Exiting before the flush
  is how a "successful" deploy loses the last messages.
- **A cancelled `spawn_blocking` task keeps running.** Tokio cannot interrupt it,
  so a blocking task must have its own bound or it will outlive the shutdown.
- **Make the grace period configurable and log when it is exceeded.** A drain that
  silently truncates is indistinguishable from a crash.

## Shared state

- **`Arc<Mutex<T>>` for a value, `Arc<RwLock<T>>` for read-mostly** — and prefer
  neither: an `mpsc` to an owning task removes the lock entirely and is usually
  the better shape.
- **Hold a lock across an `.await` only with `tokio::sync::Mutex`, and only when
  the lock genuinely must span the await.** Otherwise the await belongs outside the
  critical section; a lock held over a network round trip serialises the whole
  service.
- **`AtomicUsize` is not a substitute for a queue.** If a counter is deciding
  whether work is allowed, the check and the increment must be one operation.
- **`tokio::sync::Semaphore` for a concurrency limit**, not a hand-rolled counter:
  it acquires, queues, and releases on drop, including on panic.

## Tests

- **`#[tokio::test]` for anything async**, never a `block_on` inside a synchronous
  test.
- **Assert on observable ordering, not on sleeps.** A test that passes because it
  slept 100 ms is a test that fails on a loaded CI machine.
- **Bound the test itself.** `tokio::time::timeout` around the assertion turns a
  deadlock into a failure with a message instead of a hung suite.
- **`tokio::time::pause()` for timer logic** so a test of a 30-second timeout runs
  instantly and deterministically.
- **Test the cancel path.** Send a shutdown mid-flight and assert the drain
  completed — that is the branch that never gets exercised in normal use.

## The default lint set is not enough

`clippy` catches the mechanical cases; the ones above are mostly semantic. Two
additions pay for themselves on an async codebase:

- **`#![deny(clippy::await_holding_lock)]`** — the single highest-value async lint.
- **A test that builds a multi-threaded runtime and drives concurrent load** —
  because "works with one request at a time" is exactly the state in which none of
  these defects are visible.
