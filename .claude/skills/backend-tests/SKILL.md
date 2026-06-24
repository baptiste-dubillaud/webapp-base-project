---
name: backend-tests
description: Use when writing, reviewing, or fixing tests for the FastAPI backend — unit tests, integration/e2e tests, fixtures, or test strategy. Ensures tests are well-thought-out, relevant, behavior-focused, isolated, and fast.
---

# Backend tests

Tests exist to lock in **behavior and contracts**, so a refactor that preserves behavior never breaks
them. Prefer a few sharp, meaningful tests over many brittle ones. A feature is not done without tests
and a green `make test`.

## Layout & tooling

- `tests/unit/` — pure, fast, no app/DB. Functions and isolated classes (settings, error mapping,
  schemas, pure service logic with fakes).
- `tests/integration/` — drive the **real ASGI app** via `httpx.AsyncClient` + `ASGITransport(app)`.
  This exercises the actual middleware stack, routing, and error handlers without a socket.
- `asyncio_mode = "auto"` — write `async def test_...`; no `@pytest.mark.asyncio` needed.
- Fixtures live in `tests/conftest.py` (`app`, `client`, settings-cache reset). Keep them small and
  composable.

## What to test (relevance)

For each endpoint/behavior, cover:
- **Happy path** — correct status + response shape (assert the fields that matter, not a full snapshot).
- **Validation errors** — 422 and the error envelope.
- **Domain errors** — correct `AppError` `code` and HTTP status.
- **Authorization** — 401/403 paths (once auth lands).
- **Edge cases** — empty/boundary inputs, idempotency, pagination limits.
- **Security invariants** — secrets/internal details never appear in responses (e.g. assert a raised
  internal exception's text is absent from the 500 body); `request_id` is present.

## How to write them

- One behavior per test. Name `test_<thing>_<condition>_<expected>`. Arrange–Act–Assert.
- **Deterministic:** no reliance on wall-clock, random UUIDs, ordering, or network. Inject/freeze the
  clock and ids; sort before comparing.
- **Don't over-mock.** Prefer real objects. Mock only at boundaries you don't own (outbound HTTP,
  email sender, clock, OAuth provider). Never mock the thing under test.
- Use factories (factory-boy / polyfactory) for model/DTO instances once models stabilize — keep test
  data construction DRY and intention-revealing.

## DB-backed tests (Phase 1+)

- Use a **real Postgres** (the app depends on Postgres features: pgcrypto, triggers, cascades).
  **Never SQLite.**
- Build the schema by running the **real Alembic migrations** — this also tests the migrations.
- Each test runs in a transaction rolled back at teardown (SAVEPOINT/nested transaction) so tests are
  isolated and fast. Provide a `db` session fixture and an authenticated-client fixture in conftest.

## Anti-patterns (reject in review)

- Asserting on log output or private methods.
- Whole-response snapshot assertions that break on irrelevant changes.
- Shared mutable state between tests; order-dependent tests.
- Tests that pass without exercising the code (no meaningful assertion).
- Network calls or sleeps in unit tests.
