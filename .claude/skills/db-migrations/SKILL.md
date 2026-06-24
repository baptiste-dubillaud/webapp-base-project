---
name: db-migrations
description: Use when changing the database schema or creating/reviewing Alembic migrations for the backend — adding/altering tables or columns, indexes, constraints, enums, or seed data. Ensures schema conventions, reviewable autogenerate, reversibility, and tested migrations.
---

# Database migrations (Alembic)

Models are the **source of truth**; Alembic migrations are generated from `Base.metadata` and then
**reviewed by hand**. Migrations are versioned, reversible, and tested. (Alembic is set up in Phase 1;
follow these conventions when setting it up and for every migration after.)

## Workflow

1. Edit the SQLAlchemy models in `app/modules/<domain>/models.py`.
2. Make sure every model is imported into the Alembic metadata (the model registry) so autogenerate
   sees it — a missing import silently drops the table from the diff.
3. `alembic revision --autogenerate -m "short imperative summary"`.
4. **Review the generated file.** Autogenerate misses or mis-handles: server defaults, `enum`
   types, index/constraint renames, column type changes, and any data migration. Fix it by hand.
5. `alembic upgrade head`, then run the tests (the test schema is built from migrations).
6. Confirm `alembic downgrade -1` works (reversibility).

## Schema conventions

- **Table names:** singular snake_case (`user`, `role`, `user_role`, `auth_identity`).
- **Primary keys:** UUIDv7 **generated app-side** (do not use a server default — the legacy
  `uuid_generate_v7()` was a phantom function and broke `CREATE TABLE`). Integer PKs only for small
  lookup tables (e.g. `role`).
- **Naming convention:** `Base.metadata` uses a deterministic naming convention for constraints/indexes
  so autogenerate diffs stay stable and reviewable. Don't hand-name constraints inconsistently.
- **Timestamps:** `timestamptz` via the shared `TimestampMixin` (`server_default=now()`, `onupdate`).
- **Foreign keys:** default `ondelete="CASCADE"`. Avoid FKs that cross module boundaries where you can
  (it's the future micro-service split point); if one is necessary, note why in the migration.
- **Indexes:** add them for every FK and every column used in a `WHERE`/lookup.

## Safety

- Every migration has a working `downgrade`.
- **Never edit a migration that's already been applied/committed** — add a new one.
- Treat destructive ops (drop column/table) with care: separate them from additive changes, and never
  silently drop a column that holds data — migrate the data first or stage the removal.
- **Seeds** (default roles, bootstrap admin) are **idempotent** and belong in a dedicated seed step
  (run after `upgrade head`), kept separate from schema migrations.

## Testing migrations

- CI and the test suite run `alembic upgrade head` against a real Postgres.
- Run `alembic check` to assert there is **no drift** between the models and the latest migration
  (autogenerate would produce an empty diff). A non-empty diff fails the build.
