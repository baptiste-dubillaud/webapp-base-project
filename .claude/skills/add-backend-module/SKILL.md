---
name: add-backend-module
description: Use when adding a new feature domain to the FastAPI backend (a new app/modules/<domain>/ such as users, auth, billing, projects) or when adding endpoints/business logic that belongs to a domain. Ensures the modular-monolith architecture, layering, and dependency rules stay consistent.
---

# Add a backend module

Scaffold and wire a new feature domain under `backend/app/modules/<domain>/`, respecting the
modular-monolith conventions in `CLAUDE.md`. Optimize for maintainability and a clean micro-service
seam, not for the fewest files.

## Layout

Create `app/modules/<domain>/` with:

```
__init__.py
router.py        # APIRouter: HTTP I/O only (path/query/body, status codes, deps)
service.py       # business logic; owns the unit of work; raises AppError
repository.py    # DB access only (SQLAlchemy queries); no business rules, no HTTP
schemas.py       # Pydantic request/response DTOs (never expose ORM models)
models.py        # SQLAlchemy ORM models for this domain's tables
exceptions.py    # domain-specific AppError subclasses (stable `code`s)
```

Omit a file only if the domain genuinely has no use for it (say so).

## Rules (enforced)

1. **Layering:** `router → service → repository`. The router must not touch the repository directly.
   The service must not build HTTP responses or import FastAPI request/response types.
2. **Dependency direction:** import from `app.core.*` freely. To use another domain, import **only its
   `service`** and exchange **schemas (DTOs)** — never import another module's `repository`/`models`,
   and never return ORM objects across a module boundary. If you need a cross-module read, define a
   `Protocol` for it so the in-process call can later become a remote client.
3. **Errors:** raise `AppError` subclasses (define them in `exceptions.py`, base in
   `app/core/errors/exceptions.py`) with a stable machine `code` (e.g. `billing.invoice_not_found`).
   Never raise `HTTPException` in a service. The registered handler turns these into the error envelope.
4. **Schemas:** request and response models live in `schemas.py`; lists use `Page[T]` from
   `app/core/schemas/common.py`. Validate at the edge; pass typed objects inward.
5. **Models:** SQLAlchemy 2.0 `Mapped`/`mapped_column`, inherit `Base` (+ mixins once they exist),
   table names **singular snake_case**. New tables need an Alembic migration — use the `db-migrations`
   skill. Make sure the model is imported by the Alembic metadata/registry so autogenerate sees it.
6. **DB session:** the service receives an `AsyncSession` via the `get_db` dependency; the dependency
   owns commit/rollback (commit-on-success). Services call `flush()` for generated ids, not `commit()`.
7. **i18n:** every error `code` you introduce must have a catalog entry (once i18n lands in Phase 2).

## Wiring

Mount the router in `app/api/router.py`:

```python
from app.modules.<domain>.router import router as <domain>_router
api_router.include_router(<domain>_router, prefix="/<domain>", tags=["<domain>"])
```

Document expected error responses on routes for OpenAPI (e.g. `responses={404: {...}, 409: {...}}`).

## Done criteria

- Unit tests for the service's logic and integration tests for the router (use the `backend-tests`
  skill). Cover happy path, validation errors, domain errors, and authz where relevant.
- `make check` is green (ruff + ruff-format + mypy --strict + pytest).
- No cross-module internal imports; no ORM objects crossing module boundaries.
